import 'dart:convert';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/providers/bug_admin_provider.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BugAdminScreen extends ConsumerStatefulWidget {
  static const String route = "home/bug_admin";

  const BugAdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BugAdminScreen> createState() => _BugAdminScreenState();
}

class _BugAdminScreenState extends ConsumerState<BugAdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final ff = ref.read(bugAdminProvider.notifier);
      ff.getBugs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bugs = ref.watch(bugAdminProvider);
    return Stack(
      children: [
        const BackgroundWidget(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Header(header: 'Bug Admin'),
                  // Padding(
                  //   padding: const EdgeInsets.all(2.0),
                  //   child: FlatCustomButton(
                  //     radius: 8.0,
                  //    height: 30.0,
                  //     width: 200.0,
                  //    color: Colors.lime,
                  //    onTap: () {
                  //      Navigator.of(context).pushNamed(DonutScreen.route);
                  //    },
                  //     child: const Text('3D Donut', style: TextStyle(color: Colors.black87),),
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.all(2.0),
                  //   child: SliderWidget(
                  //     height: 100.0,
                  //     width: 200.0,
                  //     onChanged: (progress, preciseProgress) {
                  //       print("progress: $progress, preciseProgress: $preciseProgress");
                  //     },
                  //   ),
                  // ),
                  Expanded(
                    child: bugs.when(
                      data: (data) {
                        if (data.isEmpty) {
                          return Center(
                              child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Colors.black12,
                                  ),
                                  child: const Text(
                                    "No bugs submitted yet",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                                  )));
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final bug = data[index];
                                return Container(
                                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10.0),
                                          color: bug.processed == 0 ? Colors.black38 : Colors.lightGreen,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("Bug #", style: TextStyle(color: bug.processed == 1 ? Colors.black54 : Colors.white70, fontWeight: FontWeight.w600)),
                                            Text("${bug.id}", style: TextStyle(color: bug.processed == 1 ? Colors.black54 : Colors.white70, fontWeight: FontWeight.w900)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Align(alignment: Alignment.centerLeft, child: Text(" Username:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                          const SizedBox(height: 8),
                                          Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10.0),
                                                color: Colors.black12,
                                              ),
                                              child: Text(bug.username ?? "", maxLines: 6, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Align(alignment: Alignment.centerLeft, child: Text(" Description:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                          const SizedBox(height: 8),
                                          Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10.0),
                                                color: Colors.black12,
                                              ),
                                              child: Text(bug.bugDesc ?? "", maxLines: 6, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Align(alignment: Alignment.centerLeft, child: Text(" Location:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                          const SizedBox(height: 8),
                                          Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10.0),
                                                color: Colors.black12,
                                              ),
                                              child: Text(bug.bugLocation ?? "", maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Align(alignment: Alignment.centerLeft, child: Text(" Date Posted:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                          const SizedBox(height: 8),
                                          Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10.0),
                                                color: Colors.black12,
                                              ),
                                              child:
                                                  Text(Utils.convertDate(bug.dateSubmit ?? ""), textAlign: TextAlign.center, maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                        ],
                                      ),
                                      if (bug.processed == 0)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 15),
                                            FlatCustomButton(
                                              height: 40,
                                              width: double.infinity,
                                              color: Colors.lightGreen,
                                              child: const Text(
                                                "Process",
                                                style: TextStyle(color: Color(0xFF202841), fontWeight: FontWeight.w900),
                                              ),
                                              onTap: () {
                                                Dialogs.openRewardBugDialog(
                                                    context, bug.id!, bug.addr ?? "", (addr, amount, comment, idBug) => sendCoins(amount: amount, address: addr, comment: comment, idBug: idBug));
                                              },
                                            ),
                                          ],
                                        ),
                                      if (bug.processed == 1)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 10),
                                            const Align(
                                                alignment: Alignment.centerLeft, child: Text(" Date Processed:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                            const SizedBox(height: 8),
                                            Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10.0),
                                                  color: Colors.black12,
                                                ),
                                                child: Text(Utils.convertDate(bug.dateProcess ?? ""),
                                                    textAlign: TextAlign.center, maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                          ],
                                        ),
                                      if (bug.comment != null)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 10),
                                            const Align(alignment: Alignment.centerLeft, child: Text(" Comment:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                            const SizedBox(height: 8),
                                            Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10.0),
                                                  color: Colors.black12,
                                                ),
                                                child: Text(bug.comment ?? "", textAlign: TextAlign.start, maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                          ],
                                        ),
                                      if (bug.processed == 1 && bug.reward != null)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 10),
                                            const Align(alignment: Alignment.centerLeft, child: Text(" Reward:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                            const SizedBox(height: 8),
                                            Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10.0),
                                                  color: Colors.black12,
                                                ),
                                                child: Text("${bug.reward ?? 0.0} XDN", textAlign: TextAlign.center, maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                          ],
                                        ),
                                    ]));
                              }),
                        );
                      },
                      error: (err, stack) {
                        return const Text("Error loading bugs");
                      },
                      loading: () {
                        return const Center(
                            child: SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white38,
                                )));
                      },
                    ),
                  ),
                ],
              )),
        )
      ],
    );
  }

  var sending = false;

  sendCoins({required double amount, required String address, String? comment, required int idBug}) async {
    if (sending) {
      return;
    }
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    sending = true;
    Map<String, dynamic> m = {"address": address, "amount": amount, "contact": "Bug report reward"};
    Map<String, dynamic> m2 = {"id": idBug, "comment": comment, "reward": amount};
    try {
      ComInterface interface = ComInterface();
      await interface.post("/user/send/contact", body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: true);
      await interface.post("/misc/bug/process", body: m2, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: true);
      sending = false;
      final ff = ref.read(bugAdminProvider.notifier);
      ff.getBugs();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      sending = false;
      Navigator.of(context).pop();
      var err = json.decode(e.toString());
      Dialogs.openAlertBox(context, "error", err['errorMessage']);
      print(e);
    }
  }
}
