import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BalanceCardMainMenu extends StatefulWidget {
  final Future<Map<String, dynamic>>? getBalanceFuture;
  const BalanceCardMainMenu({Key? key, required this.getBalanceFuture}) : super(key: key);

  @override
  State<BalanceCardMainMenu> createState() => _BalanceCardMainMenuState();
}

class _BalanceCardMainMenuState extends State<BalanceCardMainMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
        margin: const EdgeInsets.only(left: 10.0, right: 10.0),
    decoration: const BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(15.0)),
      gradient: LinearGradient(colors: [Color(0xFF8AB1F6), Color(0xFFB2B6FC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,),
      image: DecorationImage(image: AssetImage("images/card.png"),
    fit: BoxFit.fitWidth),
    ),
    child:Center(
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
                      padding: const EdgeInsets.only(top:5.0),
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
                                    minFontSize: 18.0, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headline5!.copyWith(fontWeight: FontWeight.w200, fontSize: 28.0)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0,),
                          Container(
                              height: 45,
                              margin: const EdgeInsets.only(right: 10.0),
                              padding: const EdgeInsets.all(10.0),
                              child: const Center(child: Text("XDN", style: TextStyle(color: Colors.white54, fontSize: 18.0),))
                          ),
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: const <Widget>[
                  SizedBox(
                      height: 55.0,
                      width: 55.0,
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.white,
                        strokeWidth: 2.0,
                      )),
                ]),
              );
            }
          }),
    ),
    );
  }
}
