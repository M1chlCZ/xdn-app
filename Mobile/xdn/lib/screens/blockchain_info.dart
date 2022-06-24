import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/get_info.dart';
import 'package:digitalnote/support/summary.dart';
import 'package:digitalnote/widgets/backgroundWidget.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BlockInfoScreen extends StatefulWidget {
  static const String route = "menu/settings/block";

  const BlockInfoScreen({Key? key}) : super(key: key);

  @override
  State<BlockInfoScreen> createState() => _BlockInfoScreenState();
}

class _BlockInfoScreenState extends State<BlockInfoScreen> {
  GetInfo? getInfo;
  Sumry? sumry;

  @override
  void initState() {
    super.initState();
    getInfoGet();
  }

  getInfoGet() async {
    getInfo = await NetInterface.getInfo();
    sumry = await NetInterface.getSummary();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        arc: false,
        mainMenu: true,
      ),
      Theme(
        data: Theme.of(context).copyWith(
            textTheme: TextTheme(
          headline5: GoogleFonts.montserrat(
            color: Colors.black54,
            fontSize: 14.0,
            fontWeight: FontWeight.w300,
          ),
          bodyText2: GoogleFonts.montserrat(
            color: Colors.black54,
            fontWeight: FontWeight.w300,
          ),
        )),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Builder(
                builder: (context) => SafeArea(
                        child: SingleChildScrollView(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Header(header: "Blockchain Info"),
                      Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 15.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              AutoSizeText(
                                'Client version: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  getInfo?.version.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 20.0,),
                              AutoSizeText(
                                'Block count: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  getInfo?.blocks.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 20.0,),
                              AutoSizeText(
                                'Masternode count: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  sumry?.data?[0].masternodecount.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 15.0,),
                              AutoSizeText(
                                'POW difficulty: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  sumry?.data?[0].difficulty.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 15.0,),
                              AutoSizeText(
                                'Hashrate: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  "${sumry?.data?[0].hashrate} GH/s",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                                ),
                              ), const SizedBox(height: 15.0,),
                              AutoSizeText(
                                'Coin supply: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  "${sumry?.data?[0].supply} XDN",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 20.0,),
                            ]),
                          ))
                    ]))))),
      )
    ]);
  }
}
