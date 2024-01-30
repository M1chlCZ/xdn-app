import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/providers/balance_provider.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BalanceCardMainMenu extends ConsumerStatefulWidget {
  final VoidCallback goto;
  final VoidCallback scan;

  const BalanceCardMainMenu({Key? key, required this.goto, required this.scan}) : super(key: key);

  @override
  ConsumerState<BalanceCardMainMenu> createState() => _BalanceCardMainMenuState();
}

class _BalanceCardMainMenuState extends ConsumerState<BalanceCardMainMenu> {
  @override
  void initState() {
    // TODO: implement initState
      super.initState();

  }
  @override
  Widget build(BuildContext context) {
    var balance = ref.watch(balanceProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: GestureDetector(
        onTap: () {
          widget.goto();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(2, 4), // changes position of shadow
              ),
            ],
            image: const DecorationImage(image: AssetImage("images/test_pattern.png"), fit: BoxFit.cover, opacity: 1.0),
          ),
          height: 90,
          child: Stack(
            children: [
              Center(
                child: balance.when(
                    data: (data) {
                      Map<String, dynamic> m = data!;
                      var balance = Utils.formatBalance(double.parse(m['spendable'].toString()));
                      var immature = double.parse(m['immature'].toString()).toStringAsFixed(3);
                      var pending = double.parse(m['balance'].toString()).toStringAsFixed(3);
                      var textImature = immature == '0.000' ? '' : "${AppLocalizations.of(context)!.immature}: ${Utils.formatBalance(double.parse(immature))} XDN";
                      var textPending = double.parse(pending).toInt() == 0 ? '' : "Pending ${Utils.formatBalance(double.parse(pending))} XDN";
                      if (textImature != '' && textPending != '') {
                        textPending = '';
                      }
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12.0, right:Platform.isIOS ? 20 : 40),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 2.0, left: 10.0),
                                        child: AutoSizeText(balance,
                                            minFontSize: 18.0,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w200, fontSize: 28.0)),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Container(
                                        height: 38,
                                        margin: const EdgeInsets.only(right: 10.0, bottom: 2.0),
                                        child: Center(
                                            child: Text(
                                              "XDN",
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white70, fontSize: 24.0, fontWeight: FontWeight.w800),
                                            ))),
                                    const SizedBox(
                                      width: 0.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          textImature != ''
                              ? Padding(
                            padding: EdgeInsets.only(right: Platform.isIOS ? 20 : 40),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: AutoSizeText(textImature,
                                  minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white54)),
                            ),
                          )
                              : Container(),
                          textPending != ''
                              ? Padding(
                            padding: EdgeInsets.only(right: Platform.isIOS ? 20 : 40),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: AutoSizeText(textPending,
                                  minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white54)),
                            ),
                          )
                              : Container(),
                          const SizedBox(
                            height: 10.0,
                          ),
                        ],
                      );
                    },
                    error: (Object error, StackTrace stackTrace) {
                      Center(child: Text("There was an error retrieving you balance", style: Theme.of(context).textTheme.displayLarge!.copyWith(color: Colors.white, fontSize: 14)));
                      return null;
                    },
                    loading: () {
                      return const Center(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                          SizedBox(
                              height: 25.0,
                              width: 25.0,
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.white12,
                                color: Colors.white54,
                                strokeWidth: 1.0,
                              )),
                        ]),
                      );
                    }),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                child: SizedBox(width: 90, child: Image.asset("images/wallet_big.png")),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(15.0), bottomRight: Radius.circular(15.0)),
                  child: Material(
                    color: Colors.black12,
                    child: InkWell(
                      splashColor: Colors.black26,
                      onTap: () {
                        widget.scan();
                      },
                      child: Container(
                        height: double.infinity,
                        width: 75,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(topRight: Radius.circular(15.0), bottomRight: Radius.circular(15.0)),
                          color: Colors.transparent,
                        ),
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          "images/QR.png",
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
