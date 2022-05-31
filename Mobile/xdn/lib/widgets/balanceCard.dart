import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/ColorScheme.dart';
import '../support/Dialogs.dart';

class BalanceCard extends StatefulWidget {
  final Future<Map<String,dynamic>>? getBalanceFuture;
  final VoidCallback? onPressSend;

  const BalanceCard({Key? key, this.getBalanceFuture, this.onPressSend}) : super(key: key);

  BalanceCardState createState() => BalanceCardState();
}

class BalanceCardState extends State<BalanceCard> {
  final key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 40.0, left: 10.0, right: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          child: PhysicalModel(
            color: Theme.of(context).konjHeaderColor,
            shadowColor: Colors.black45,
            elevation: 5,
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Column(
                children: <Widget>[
                  SizedBox(height: 10),
                  FutureBuilder<Map<String, dynamic>>(
                      future: widget.getBalanceFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          Map<String, dynamic> m = snapshot.data!;
                          var balance = m['balance'].toString();
                          var immature = m['immature'].toString();
                          var textImature = immature == '0.000' ? '' : AppLocalizations.of(context)!.immature + ": " + immature + " KONJ";
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top:5.0),
                                child: Container(
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
                                              minFontSize: 18.0, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontWeight: FontWeight.w200, fontSize: 28.0)),
                                        ),
                                      ),
                                    ),
                                      SizedBox(width: 10.0,),
                                      Container(
                                          height: 45,
                                          margin: EdgeInsets.only(right: 10.0),
                                          padding: EdgeInsets.all(10.0),
                                          child: Center(child: Text("KONJ", style: TextStyle(color: Colors.white54, fontSize: 18.0),))
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              textImature != ''
                                  ? SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      child: AutoSizeText(textImature,
                                          minFontSize: 12.0, maxLines: 1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0, color: Colors.white54)),
                                    )
                                  : Container(),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString(), style: Theme.of(context).textTheme.headline1));
                        } else {
                          return Container(
                            child: Center(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                SizedBox(
                                    child: CircularProgressIndicator(
                                      backgroundColor: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                    height: 55.0,
                                    width: 55.0),
                              ]),
                            ),
                          );
                        }
                      }),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.005,
                  ),
                  Container(
                    margin: EdgeInsets.all(5.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(
                        width: 130.0,
                        height: 47.0,
                        child: TextButton(
                          clipBehavior: Clip.antiAlias,
                          onPressed: () {
                            Dialogs.openUserQR(context);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.receive,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(20, 20),
                              alignment: Alignment.center,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.white12),
                                borderRadius: BorderRadius.circular(15.0),
                              )),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      SizedBox(
                        width: 130.0,
                        height: 47.0,
                        child: TextButton(
                          clipBehavior: Clip.antiAlias,
                          onPressed: widget.onPressSend,
                          child: Text(
                            AppLocalizations.of(context)!.send,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(20, 20),
                              alignment: Alignment.center,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.white12),
                                borderRadius: BorderRadius.circular(15.0),
                              )),
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
