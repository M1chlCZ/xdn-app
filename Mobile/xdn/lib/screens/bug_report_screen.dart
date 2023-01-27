import 'dart:convert';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BugReportScreen extends StatefulWidget {
  static const String route = 'home/bug_report';

  const BugReportScreen({Key? key}) : super(key: key);

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();

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
  Widget build(BuildContext context) {
    return Scaffold(body:
    Stack(
      children: [
        const BackgroundWidget(),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children:[
              const Header(header: "Bug Report"),
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
                    children: [
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
                      const SizedBox(height: 10.0),
                      const Text("Please report any bugs you find to the developers", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 10.0),
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
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: OutlineInputBorder(
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
                            style: const TextStyle(color: Colors.white70),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder( borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            labelText: 'Bug Description',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Theme(
                        data: ThemeData(
                          primaryColor: Colors.white70,
                          primaryColorDark: Colors.white70,
                          indicatorColor: Colors.white70,
                          inputDecorationTheme: const InputDecorationTheme(
                            labelStyle: TextStyle(color: Colors.white30),
                            hintStyle: TextStyle(color: Colors.white12),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: OutlineInputBorder(
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
                          style: const TextStyle(color: Colors.white70),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder( borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            labelText: 'Where bug appeared',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
          ]),
        ),
      ],
    ),);
  }
}
