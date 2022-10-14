import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/Dialogs.dart';

class BalanceCard extends StatefulWidget {
  final Future<Map<String, dynamic>>? getBalanceFuture;
  final VoidCallback? onPressSend;

  const BalanceCard({Key? key, this.getBalanceFuture, this.onPressSend}) : super(key: key);

  @override
  BalanceCardState createState() => BalanceCardState();
}

class BalanceCardState extends State<BalanceCard> {
  final key = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _priceData;

  @override
  void initState() {
    super.initState();
    getPriceData();
  }

  void getPriceData() async {
    _priceData = await NetInterface.getPriceData();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10.0, right: 10.0),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            gradient: LinearGradient(
              colors: [Color(0xFF313C5D),
                Color(0xFF5469BE)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            image: DecorationImage(image: AssetImage("images/test_pattern.png"), fit: BoxFit.fill, opacity: 0.8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(
              children: <Widget>[
                const SizedBox(height: 10),
                FutureBuilder<Map<String, dynamic>>(
                    future: widget.getBalanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        Map<String, dynamic> m = snapshot.data!;
                        var balance = double.parse(m['spendable'].toString()).toStringAsFixed(3);
                        var immature = double.parse(m['immature'].toString()).toStringAsFixed(3);

                        var textImature = immature == '0.000' ? '' : "${AppLocalizations.of(context)!.immature}: $immature XDN";
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.5,
                                      height: 40,
                                      child: Center(
                                        child: AutoSizeText(balance,
                                            minFontSize: 18.0,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w200, fontSize: 28.0)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                  Container(
                                      height: 45,
                                      margin: const EdgeInsets.only(right: 10.0),
                                      padding: const EdgeInsets.all(10.0),
                                      child: const Center(
                                          child: Text(
                                            "XDN",
                                            style: TextStyle(color: Colors.white54, fontSize: 18.0),
                                          ))),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            _priceData != null &&  _priceData!.isNotEmpty
                                ? SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: AutoSizeText("${((_priceData!['usd'] * double.parse(m['balance'].toString())) as double).toStringAsFixed(4)} USD",
                                  minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0, fontWeight: FontWeight.w400, color: Colors.white54)),
                            )
                                : Container(),
                            const SizedBox(
                              height: 2,
                            ),
                            textImature != ''
                                ? SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: AutoSizeText(textImature,
                                  minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0, color: Colors.white54)),
                            )
                                : Container(),
                            const SizedBox(
                              height: 2,
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString(), style: Theme.of(context).textTheme.headline1!.copyWith(fontSize: 12.0, color: Colors.redAccent)));
                      } else {
                        return Center(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: const <Widget>[
                            SizedBox(
                                height: 75.0,
                                width: 75.0,
                                child: Center(
                                  child: SizedBox(
                                    height: 25.0,
                                    width: 25.0,
                                    child: CircularProgressIndicator(
                                      backgroundColor: Colors.transparent,
                                      color: Colors.white54,
                                      strokeWidth: 1.0,
                                    ),
                                  ),
                                )),
                          ]),
                        );
                      }
                    }),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.005,
                ),
                Container(
                  margin: const EdgeInsets.all(5.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(
                      width: 130.0,
                      height: 47.0,
                      child: TextButton(
                        clipBehavior: Clip.antiAlias,
                        onPressed: () {
                          Dialogs.openUserQR(context);
                        },
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(20, 20),
                            alignment: Alignment.center,
                            backgroundColor: Colors.black.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.white30),
                              borderRadius: BorderRadius.circular(15.0),
                            )),
                        child: Text(
                          AppLocalizations.of(context)!.receive,
                          style: Theme.of(context).textTheme.bodyText2!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                    ),
                    SizedBox(
                      width: 130.0,
                      height: 47.0,
                      child: TextButton(
                        clipBehavior: Clip.antiAlias,
                        onPressed: widget.onPressSend,
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(20, 20),
                            alignment: Alignment.center,
                            backgroundColor: Colors.black.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.white30),
                              borderRadius: BorderRadius.circular(15.0),
                            )),
                        child: Text(
                          AppLocalizations.of(context)!.send,
                          style: Theme.of(context).textTheme.bodyText2!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ]),
        ),
      ],
    );
  }
}