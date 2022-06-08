import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BalanceCardMainMenu extends StatefulWidget {
  final Future<Map<String, dynamic>>? getBalanceFuture;
  final VoidCallback goto;

  const BalanceCardMainMenu({Key? key, required this.getBalanceFuture, required this.goto}) : super(key: key);

  @override
  State<BalanceCardMainMenu> createState() => _BalanceCardMainMenuState();
}

class _BalanceCardMainMenuState extends State<BalanceCardMainMenu> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: GestureDetector(
        onTap: () {
          widget.goto();
        },
        child: Container(
          decoration:  BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            gradient: const LinearGradient(
              colors: [Color(0xFF3D3E4B),
                Color(0xFF262C44)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 3,
                offset: const Offset(0, 5), // changes position of shadow
              ),
            ],
            image: DecorationImage(image: AssetImage("images/card.png"), fit: BoxFit.fitWidth, opacity: 1),
          ),
          height: 100,
          child: Center(
            child: FutureBuilder<Map<String, dynamic>>(
                future: widget.getBalanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Map<String, dynamic> m = snapshot.data!;
                    var balance = m['balance'].toString();
                    var immature = m['immature'].toString();
                    var textImature = immature == '0.000' ? '' : "${AppLocalizations.of(context)!.immature}: $immature XDN";
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: SizedBox(
                                    width: 220,
                                    height: 40,
                                    child: Center(
                                      child: AutoSizeText(balance,
                                          minFontSize: 18.0,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontWeight: FontWeight.w200, fontSize: 28.0)),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Container(
                                    height: 45,
                                    margin: const EdgeInsets.only(right: 10.0, bottom: 2.0),
                                    child: Center(
                                        child: Text(
                                      "XDN",
                                      style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white70,  fontSize: 22.0, fontWeight: FontWeight.w600),
                                    ))),
                              ],
                            ),
                          ),
                          const SizedBox(
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
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString(), style: Theme.of(context).textTheme.headline1));
                  } else {
                    return Center(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center, children: const <Widget>[
                        SizedBox(
                            height: 25.0,
                            width: 25.0,
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.white12,
                              color: Colors.blue,
                              strokeWidth: 2.0,
                            )),
                      ]),
                    );
                  }
                }),
          ),
        ),
      ),
    );
  }
}
