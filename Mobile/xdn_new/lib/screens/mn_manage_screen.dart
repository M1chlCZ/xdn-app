import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/models/MasternodeInfo.dart';
import 'package:digitalnote/net_interface/app_exception.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MasternodeManageScreen extends StatefulWidget {
  static const String route = "menu/masternode/manage";
  final MasternodeInfo mnInfo;

  const MasternodeManageScreen({super.key, required this.mnInfo});

  @override
  State<MasternodeManageScreen> createState() => _MasternodeManageScreenState();
}

class _MasternodeManageScreenState extends State<MasternodeManageScreen> {
  ComInterface interface = ComInterface();
  List<dynamic> sortedList = [];

  @override
  void initState() {
    super.initState();
    var s = widget.mnInfo.mnList!;
    Iterable<MnList> non = s.where((element) => element.custodial == false);
    Iterable<MnList> cus = s.where((element) => element.custodial == true);

    if (non.isNotEmpty) {
      sortedList.add("Non-Custodial");
      List<MnList> l = non.toList();
      l.sort((a, b) => a.id!.compareTo(b.id!));
      sortedList.addAll(l);
    }
    if (cus.isNotEmpty) {
      if (cus.isNotEmpty) sortedList.add("Custodial");
      List<MnList> l = cus.toList();
      l.sort((a, b) => a.id!.compareTo(b.id!));
      sortedList.addAll(l);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(
          mainMenu: false,
        ),
        Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [
                Header(
                  header: "Manage MN".toUpperCase(),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                Flexible(
                  child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedList.length,
                      itemBuilder: (context, index) {
                        if (sortedList[index] is String) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sortedList[index],
                                  style: GoogleFonts.dosis(color: Colors.white70,fontWeight: FontWeight.w500, fontSize: 14.0),
                                ),
                                const Divider(
                                  color: Colors.white30,
                                  thickness: 1.0,
                                ),
                              ],
                            ),
                          );
                        } else if (sortedList[index] is MnList) {
                          return Container(
                            key: ValueKey(sortedList[index].id),
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.white.withOpacity(0.05),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                        width: 85.0,
                                        height: 40.0,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10.0),
                                            bottomLeft: Radius.circular(10.0),
                                          ),
                                          color: Colors.black12,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text(
                                              "${sortedList[index].id}",
                                              style: GoogleFonts.dosis(fontSize: 24.0,fontWeight: FontWeight.w400, color: Colors.white70),
                                            ),
                                          ),
                                        )),
                                    Expanded(
                                      child: Container(
                                        height: 40.0,
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(10.0),
                                            bottomRight: Radius.circular(10.0),
                                          ),
                                          color: Colors.black26,
                                        ),
                                        child: Text(
                                          "${sortedList[index].ip}",
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontSize: 14.0, color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Colors.black26,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const AutoSizeText(
                                            "Running time:",
                                            maxLines: 1,
                                            minFontSize: 8,
                                            style: TextStyle(fontSize: 14.0, color: Colors.white70),
                                          ),
                                          const SizedBox(
                                            width: 20.0,
                                          ),
                                          Expanded(
                                            child: AutoSizeText(
                                              timeActive(sortedList[index].timeActive ?? 0),
                                              maxLines: 1,
                                              minFontSize: 8,
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(fontSize: 14.0, color: Colors.white70),
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (sortedList[index].custodial == true)
                                       Column(children: [
                                         const SizedBox(
                                           height: 10.0,
                                         ),
                                         Row(
                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                           children: [
                                             const AutoSizeText(
                                               "Average payrate:",
                                               maxLines: 1,
                                               minFontSize: 8,
                                               style: TextStyle(fontSize: 14.0, color: Colors.white70),
                                             ),
                                             const SizedBox(
                                               width: 20.0,
                                             ),
                                             Expanded(
                                               child: AutoSizeText(
                                                 averagePayFormat(sortedList[index].averagePayTime.toString()),
                                                 maxLines: 1,
                                                 minFontSize: 8,
                                                 textAlign: TextAlign.end,
                                                 style: const TextStyle(fontSize: 14.0, color: Colors.white70),
                                               ),
                                             ),
                                           ],
                                         ),
                                       ],),
                                      const SizedBox(
                                        height: 10.0,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const AutoSizeText(
                                            "Last seen:",
                                            maxLines: 1,
                                            minFontSize: 8,
                                            style: TextStyle(fontSize: 14.0, color: Colors.white70),
                                          ),
                                          AutoSizeText(
                                            Utils.convertDate(sortedList[index].lastSeen),
                                            maxLines: 1,
                                            minFontSize: 8,
                                            style: const TextStyle(fontSize: 14.0, color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    if (sortedList[index].custodial == false)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 2.0),
                                        child: FlatCustomButton(
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: const Color(0xFF2B3146),
                                                  content: Align(alignment: Alignment.center, child: Text('Long press to restart MN', style: GoogleFonts.montserrat(fontSize: 18.0, color: Colors.white70, fontWeight: FontWeight.w500),)),
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            onLongPress: () {
                                              _restartNode(sortedList[index].id!);
                                            },
                                            radius: 8.0,
                                            color: Colors.transparent,
                                            child:   const Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: Text(
                                                "RESTART",
                                                style: TextStyle(fontFamily: 'JosefinSans', color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            )),
                                      ),
                                    if (sortedList[index].custodial == true)
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 2.0),
                                          child: FlatCustomButton(
                                              onTap: () {
                                                Utils.openLink("https://xdn-explorer.com/address/${sortedList[index].address}");
                                              },
                                              color: Colors.transparent,
                                              child: const Padding(
                                                padding: EdgeInsets.all(5.0),
                                                child: Text(
                                                  "INFO",
                                                  style: TextStyle(fontFamily: 'JosefinSans', color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600),
                                                ),
                                              )),
                                        ),
                                        const SizedBox(
                                          width: 10.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 2.0),
                                          child: FlatCustomButton(
                                              onTap: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: const Color(0xFF2B3146),
                                                    content: Align(alignment: Alignment.center, child: Text('Long press to withdraw MN', style: GoogleFonts.montserrat(fontSize: 18.0, color: Colors.white70, fontWeight: FontWeight.w500),)),
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                              onLongPress: () {
                                                Dialogs.openMNWithdrawBox(context, sortedList[index].id!, () {
                                                  _withdrawNode(sortedList[index].id!);
                                                });
                                                // Dialogs.openAlertBox(context, "Info", "Not implemented");
                                              },
                                              color: Colors.transparent,
                                              child: const Padding(
                                                padding: EdgeInsets.all(5.0),
                                                child: Text(
                                                  "WITHDRAW",
                                                  style: TextStyle(fontFamily: 'JosefinSans', color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600),
                                                ),
                                              )),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        }else{
                          return Container();
                        }
                      }),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  _restartNode(int id) async {
    try {
      Map<String, dynamic> m = {"idNode": id};
      await interface.post("/masternode/non/restart", body: m, serverType: ComInterface.serverGoAPI, debug: true);
      if (mounted) Dialogs.openAlertBox(context, "Info", "Node $id restarted successfully");
    } catch (e) {
      Dialogs.openAlertBox(context, "Error", e.toString());
    }
  }

  _withdrawNode(int id) async {
    try {
      Map<String, dynamic> m = {"idNode": id};
      await interface.post("/masternode/withdraw", body: m, serverType: ComInterface.serverGoAPI, debug: true);
      if (mounted) Dialogs.openAlertBox(context, "Info", "Tokens are on the way!");
    } catch (ee) {
      try {
        var err = ee as ConflictDataException;
        Dialogs.openAlertBox(context, "Error", err.toString());
      } catch (e) {
        Dialogs.openAlertBox(context, "Error", ee.toString());
      }
    }
  }

  String averagePayFormat(String s) {
    if (s == "0") {
      return "Waiting for first reward";
    } else if (s == "00:00:00.000000") {
      return "Only 1 reward received";
    } else {
      var split = s.split(".");
      return split[0];
    }
  }

  String timeActive(int s) {
    if (s == 0) {
      return "Node just started";
    } else {
      var time = Duration(seconds: s);
      return Utils.formatDuration(time);
    }
  }
}
