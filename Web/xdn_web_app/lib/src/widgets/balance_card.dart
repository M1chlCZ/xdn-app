import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/provider/balance_provider.dart';
import 'package:xdn_web_app/src/support/s_p.dart';
import 'package:xdn_web_app/src/support/utils.dart';

class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({
    super.key,
  });

  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> {
  Map<String, dynamic>? _priceData;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _getPriceData();
    });
  }

  _getPriceData() async {
    final net = ref.read(networkProvider);
    Map<String, dynamic> res = await net.get("/price/data", request: {}, serverType: ComInterface.serverGoAPI, debug: true);
    setState(() {
      _priceData = res['data'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(balanceProvider);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isBig = width > 600;
    return AnimatedContainer(
      width: isBig ? 600 : width * 0.95,
      height: height * 0.15,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        image: const DecorationImage(
          image: AssetImage("assets/images/test_pattern.png"),
          fit: BoxFit.cover,
          opacity: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 4,
            blurRadius: 15,
            offset: const Offset(0, 5), // changes position of shadow
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastLinearToSlowEaseIn,
      child: balance.when(
          data: (data) {
            Map<String, dynamic> m = data;
            var balance = Utils.formatBalance(double.parse(m['spendable'].toString()));
            var immature = double.parse(m['immature'].toString()).toStringAsFixed(3);
            var pending = double.parse(m['balance'].toString()).toStringAsFixed(3);
            var textImature = immature == '0.000' ? '' : "immature: ${Utils.formatBalance(double.parse(immature))} XDN";
            var textPending = double.parse(pending).toInt() == 0 ? '' : "Pending ${Utils.formatBalance(double.parse(pending))} XDN";
            if (textImature != '' && textPending != '') {
              textPending = '';
            }
            var priceData = _priceData?['usd'] ?? 0.0;
            double price = priceData * double.parse(m['spendable'].toString());
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                    alignment: Alignment.center,
                    children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: EdgeInsets.only(right: isBig ? 80 : width * 0.12, left: isBig ? 80 : width * 0.12),
                      child: AutoSizeText(
                        balance.toString(),
                        maxLines: 1,
                        minFontSize: 8.0,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70, fontSize: 48, fontWeight: FontWeight.w100),
                      ),
                    ),
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: isBig ? 20 : width * 0.02, top: 12.0),
                        child: Container(
                            width: isBig ? 70 : width * 0.12,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AutoSizeText(
                              "XDN",
                              maxLines: 1,
                              minFontSize: 8.0,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displayLarge!.copyWith(color: Colors.white70, fontWeight: FontWeight.w800),
                            )),
                      )),
                ]),
                const SizedBox(
                  height: 2,
                ),
                _priceData != null && _priceData!.isNotEmpty && textImature == '' && textPending == ''
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: AutoSizeText("\$ ${price.toStringAsFixed(2)}",
                            minFontSize: 12.0,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, fontWeight: FontWeight.w400, color: Colors.white54)),
                      )
                    : Container(),
                const SizedBox(
                  height: 2,
                ),
                textImature != ''
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: AutoSizeText(textImature,
                            minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white54)),
                      )
                    : Container(),
                textPending != ''
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: AutoSizeText(textPending,
                            minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white54)),
                      )
                    : Container(),
                const SizedBox(
                  height: 2,
                ),
              ],
            );
          },
          loading: () => const Center(
                  child: SizedBox(
                      child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.white70,
              ))),
          error: (error, stack) => Text(error.toString())),
    );
  }
}
