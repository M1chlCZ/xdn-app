import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BalanceTokenCardMenu extends StatefulWidget {
  final Future<Map<String, dynamic>>? getBalanceFuture;
  final VoidCallback goto;

  const BalanceTokenCardMenu({Key? key, required this.getBalanceFuture, required this.goto}) : super(key: key);

  @override
  State<BalanceTokenCardMenu> createState() => _BalanceTokenCardMenuState();
}

class _BalanceTokenCardMenuState extends State<BalanceTokenCardMenu> {
  bool _tokenConnected = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: GestureDetector(
        onTap: () {
          if (_tokenConnected) {
            widget.goto();
          }
        },
        child: Container(
          decoration:  BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 3,
                offset: const Offset(0, 5), // changes position of shadow
              ),
            ],
            image: const DecorationImage(image: AssetImage("images/test_pattern.png"), fit: BoxFit.cover, opacity: 1.0),
          ),
          height: 90,
          child: Stack(
            children: [
              Center(
                child: FutureBuilder<Map<String, dynamic>>(
                    future: widget.getBalanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        Map<String, dynamic> m = snapshot.data!;
                        var balance = double.parse(m['balance'].toString());
                        var immature = '0.000';
                        var textImature = immature == '0.000' ? '' : "${AppLocalizations.of(context)!.immature}: $immature XDN";
                        _tokenConnected = true;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 2.0, left: 10.0),
                                        child: SizedBox(
                                          height: 38,
                                          child: AutoSizeText(Utils.formatBalance(balance),
                                              minFontSize: 18.0,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context).textTheme.headline5!.copyWith(fontWeight: FontWeight.w200, fontSize: 28.0)),
                                        ),
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
                                              "WXDN",
                                              style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white70,  fontSize: 24.0, fontWeight: FontWeight.w800),
                                            ))),
                                    const SizedBox(
                                      width: 78.0,
                                    ),
                                  ],

                                ),
                              ),
                              textImature != ''
                                  ? SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: AutoSizeText(textImature,
                                    minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0, color: Colors.white54)),
                              )
                                  : Container(),

                            ],
                          ),
                        );
                      } else if (snapshot.hasError) {
                        _tokenConnected = false;
                        return Center(child: Container(
                          padding: const EdgeInsets.all(5.0),

                            decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 3,
                              offset: const Offset(0, 2), // changes position of shadow
                            ),
                            BoxShadow(
                              color: Color(0xFF233261).withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 3,
                              offset: const Offset(3, 5), // changes position of shadow
                            )
                          ],
                          image: const DecorationImage(image: AssetImage("images/test_pattern.png"), fit: BoxFit.cover, opacity: 1.0),
                        ), child: Text('Connect your BSC wallet in Voting section'.capitalize(), style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0,
                            color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w800),)));
                      } else {
                        return Center(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center, children: const <Widget>[
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
                      }
                    }),
              ),
              Padding(
                padding: const EdgeInsets.only(left:2.0, top: 2.0, bottom: 2.0),
                child: SizedBox(
                    width: 90,
                    child: Image.asset("images/wallet_bsc.png")),
              )
            ],
          ),
        ),
      ),
    );
  }
}
