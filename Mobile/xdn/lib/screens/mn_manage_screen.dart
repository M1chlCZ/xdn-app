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

class MasternodeManageScreen extends StatefulWidget {
  static const String route = "menu/masternode/manage";
  final MasternodeInfo mnInfo;

  const MasternodeManageScreen({Key? key, required this.mnInfo}) : super(key: key);

  @override
  State<MasternodeManageScreen> createState() => _MasternodeManageScreenState();
}

class _MasternodeManageScreenState extends State<MasternodeManageScreen> {
  ComInterface interface = ComInterface();
  List<MnList> sortedList = [];

  @override
  void initState() {
    super.initState();
    sortedList = widget.mnInfo.mnList!;
    sortedList.sort((a, b) {
      var A = a.id!;
      var B = b.id!;
      return A.compareTo(B);
    });
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
                        return Container(
                          key: ValueKey(sortedList[index].id),
                          margin: const EdgeInsets.all(10.0),
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
                                        child: Text(
                                          "${sortedList[index].id}",
                                          style: const TextStyle(fontSize: 24.0, color: Colors.white70),
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
                                  //add some actions, icons...etc
                                  // FlatCustomButton(
                                  //     onTap: () {
                                  //       Dialogs.openAlertBox(context, "Info", "Not yet implemented");
                                  //     },
                                  //     color: Colors.transparent,
                                  //     child: const Text(
                                  //       "INFO",
                                  //       style: TextStyle(color: Colors.white24),
                                  //     )),
                                  // const SizedBox(
                                  //   width: 20.0,
                                  // ),
                                  // Padding(
                                  //   padding: const EdgeInsets.only(right:2.0),
                                  //   child: FlatCustomButton(
                                  //       onTap: () {
                                  //         Dialogs.openMNWithdrawBox(context, sortedList[index].id!, () {
                                  //           _withdrawNode(sortedList[index].id!);
                                  //         });
                                  //         // Dialogs.openAlertBox(context, "Info", "Not implemented");
                                  //       },
                                  //       color: Colors.transparent,
                                  //       child: const Padding(
                                  //         padding: EdgeInsets.all(5.0),
                                  //         child: Text(
                                  //           "INFO",
                                  //           style: TextStyle(fontFamily: 'JosefinSans',color: Colors.lime, fontSize: 14, fontWeight: FontWeight.w600),
                                  //         ),
                                  //       )),
                                  // ),
                                  // const SizedBox(
                                  //   width: 10.0,
                                  // ),
                                  Padding(
                                    padding: const EdgeInsets.only(right:2.0),
                                    child: FlatCustomButton(
                                        onTap: () {
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
                                            style: TextStyle(fontFamily: 'JosefinSans',color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600),
                                          ),
                                        )),
                                  )
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
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
