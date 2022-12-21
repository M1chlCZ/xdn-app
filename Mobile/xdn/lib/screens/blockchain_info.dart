import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/daemon_status.dart';
import 'package:digitalnote/widgets/backgroundWidget.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlockInfoScreen extends StatefulWidget {
  static const String route = "menu/settings/block";

  const BlockInfoScreen({Key? key}) : super(key: key);

  @override
  State<BlockInfoScreen> createState() => _BlockInfoScreenState();
}

class _BlockInfoScreenState extends State<BlockInfoScreen> {
  DaemonStatus? dm;

  @override
  void initState() {
    super.initState();
    getInfoGet();
  }

  Future<DaemonStatus> getDaemonStatus() async {
    try {
      ComInterface cm = ComInterface();
      Map<String, dynamic> req = await cm.get("/status", serverType: ComInterface.serverGoAPI, debug:true);
      DaemonStatus dm = DaemonStatus.fromJson(req['data']);
      return dm;
    } catch (e) {
      debugPrint(e.toString());
      return DaemonStatus(block: false, blockStake: false, stakingActive: false);
    }
  }

  getInfoGet() async {
    dm = await getDaemonStatus();
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
          headlineSmall: GoogleFonts.montserrat(
            color: Colors.black54,
            fontSize: 14.0,
            fontWeight: FontWeight.w300,
          ),
          bodyMedium: GoogleFonts.montserrat(
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
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  dm?.version ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 20.0,),
                              AutoSizeText(
                                'Block count: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  dm?.blockCount.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 20.0,),
                              AutoSizeText(
                                'Masternode count: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  dm?.masternodeCount.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 15.0,),
                              AutoSizeText(
                                'POW difficulty: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  dm?.difficulty.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 15.0,),
                              AutoSizeText(
                                'Hashrate: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  "${dm?.hashrate} GH/s",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                                ),
                              ), const SizedBox(height: 15.0,),
                              AutoSizeText(
                                'Coin supply: ',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 5.0,),
                              const Divider(height: 0.5, color: Colors.white30,),
                              const SizedBox(height: 5.0,),
                              Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(
                                  "${Utils.formatBalance(dm?.coinSupply ?? 0)} XDN",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
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
