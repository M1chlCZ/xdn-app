import 'dart:convert';
import 'dart:io';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/providers/bug_provider.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/keyboard_overlay.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/bug_switch.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BugReportScreen extends ConsumerStatefulWidget {
  static const String route = 'home/bug_report';

  const BugReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends ConsumerState<BugReportScreen> {
  final _switchKey = GlobalKey<BugSwitcherState>();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  FocusNode focusNode = FocusNode();
  FocusNode focusNode2 = FocusNode();

  var page = 0;

  @override
  void initState() {
    super.initState();
    _getFocusIOS();
    Future.delayed(Duration.zero, () {
      final ff = ref.read(bugProvider.notifier);
      ff.getBugs();
    });
  }

  void submit() async {
    ComInterface net = ComInterface();
    String bugDesc = _controller.text;
    String bugLoc = _controller2.text;
    if (bugDesc.isEmpty) {
      Dialogs.openAlertBox(context, "Error", "Please enter a bug description");
      return;
    }
    if (bugLoc.isEmpty) {
      Dialogs.openAlertBox(context, "Error", "Please enter a bug location");
      return;
    }
    try {
      Dialogs.openWaitBox(context);
      await net.post("/misc/bug/report", body: {"bugDesc": bugDesc, "bugLocation": bugLoc}, serverType: ComInterface.serverGoAPI);
      if(mounted) Navigator.of(context).pop();
      _controller.clear();
      _controller2.clear();
      if(mounted) Dialogs.openAlertBox(context, "Success", "Bug report submitted");
    } catch (e) {
      debugPrint(e.toString());
      if(mounted) Navigator.of(context).pop();
      var err = json.decode(e.toString());
      Dialogs.openAlertBox(context, "Error", err['errorMessage']);
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var bugs = ref.watch(bugProvider);
    return Scaffold(
      body: Stack(
      children: [
        const BackgroundWidget(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                const Header(header: "Bug Report"),
                BugSwitcher(
                  key: _switchKey,
                  switchPage: (int p) {
                    setState(() {
                      page = p;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      IgnorePointer(
                        ignoring: page == 0 ? false : true,
                        child: Visibility(
                          visible: page == 0 ? true : false,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children:[
                                Container(
                                  margin: const EdgeInsets.all(5),
                                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 3,
                                        blurRadius: 4,
                                        offset: const Offset(0, 3), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 5),
                                        const Text("Please report any bugs you find to the developers", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white38)),
                                        const SizedBox(height: 5.0),
                                        const SizedBox(height: 10),
                                        Theme(
                                          data: ThemeData(
                                            primaryColor: Colors.white70,
                                            primaryColorDark: Colors.white70,
                                            indicatorColor: Colors.white70,
                                            inputDecorationTheme: const InputDecorationTheme(
                                              labelStyle: TextStyle(color: Colors.white30),
                                              hintStyle: TextStyle(color: Colors.white12),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                                borderSide: BorderSide(color: Colors.white24),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                                borderSide: BorderSide(color: Colors.white54),
                                              ),
                                              fillColor: Colors.black38,
                                              filled: true,
                                            ),
                                          ),
                                          child: TextField(
                                            maxLines: 30,
                                            minLines: 5,
                                            inputFormatters: <TextInputFormatter>[
                                              FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z.,! ]")),
                                            ],
                                            controller: _controller,
                                            focusNode: focusNode,
                                              style: const TextStyle(color: Colors.white70),
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder( borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                              labelText: 'Bug Description',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Theme(
                                          data: ThemeData(
                                            primaryColor: Colors.white70,
                                            primaryColorDark: Colors.white70,
                                            indicatorColor: Colors.white70,
                                            inputDecorationTheme: const InputDecorationTheme(
                                              labelStyle: TextStyle(color: Colors.white30),
                                              hintStyle: TextStyle(color: Colors.white12),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                                borderSide: BorderSide(color: Colors.white24),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                                borderSide: BorderSide(color: Colors.white54),
                                              ),
                                              fillColor: Colors.black38,
                                              filled: true,
                                            ),
                                          ),
                                          child: TextField(
                                            maxLines: 3,
                                            minLines: 1,
                                            inputFormatters: <TextInputFormatter>[
                                              FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z.,! ]")),
                                            ],
                                            controller: _controller2,
                                            focusNode: focusNode2,
                                            style: const TextStyle(color: Colors.white70),
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder( borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                              labelText: 'Where bug appeared',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: const [
                                                Text("< Reward for submitting bug >", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white70)),
                                                SizedBox(height: 10.0),
                                                Text("Security bug 10k XDN", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.pink)),
                                                SizedBox(height: 10.0),
                                                Text("App bug 2k XDN", textAlign: TextAlign.start, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber)),
                                                SizedBox(height: 10.0),
                                                Text("Minor bug 500 XDN", textAlign: TextAlign.start, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                                                SizedBox(height: 5),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 30.0),
                                        FlatCustomButton(
                                          radius: 8,
                                          color: Colors.pink,
                                          splashColor: Colors.pinkAccent,
                                          onTap: () {
                                            submit();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Text("Submit", style: TextStyle(color: Colors.white70)),
                                                SizedBox(width: 10),
                                                Icon(Icons.send, color: Colors.white70),
                                              ],
                                            ),
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                            ]),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: page == 0 ? true : false,
                        child: Visibility(
                          visible: page == 0 ? false : true,
                          child: bugs.when(
                            data: (data) {
                              if (data.isEmpty) {
                                return Center(child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.black12,
                                    ),
                                    child: const Text("No bugs submitted yet", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),)));
                              }
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var bug in data)
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
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
                                                      child: Text(Utils.convertDate(bug.dateSubmit ?? ""), textAlign: TextAlign.center, maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                                ],
                                              ),
                                              if (bug.processed == 1)
                                                Column(
                                                  children: [
                                                    const SizedBox(height: 10),
                                                    const Align(alignment: Alignment.centerLeft, child: Text(" Date Processed:", style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600))),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(10.0),
                                                          color: Colors.black12,
                                                        ),
                                                        child: Text(Utils.convertDate(bug.dateProcess ?? ""), textAlign: TextAlign.center, maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                                  ],
                                                ),
                                              if (bug.comment != null)
                                                Column(
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
                                                        child: Text("${bug.reward ?? 0.0} XDN" , textAlign: TextAlign.center, maxLines: 4, style: const TextStyle(color: Colors.white70, fontSize: 12.0))),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            error: (err, stack) {
                              return const Text("Error loading bugs");
                            },
                            loading:() {return const Center(child: SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white38,)));},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),);
  }

  void _getFocusIOS() {
    if (Platform.isIOS) {
      focusNode.addListener(() {
        bool hasFocus = focusNode.hasFocus;
        if (hasFocus) {
          KeyboardOverlay.showOverlay(context);
        } else {
          KeyboardOverlay.removeOverlay();
        }
      });
      focusNode2.addListener(() {
        bool hasFocus = focusNode2.hasFocus;
        if (hasFocus) {
          KeyboardOverlay.showOverlay(context);
        } else {
          KeyboardOverlay.removeOverlay();
        }
      });
    }
  }
}
