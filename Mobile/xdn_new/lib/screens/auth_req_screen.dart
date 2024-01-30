import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/models/WithReq.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:flutter/material.dart';

class AuthReqScreen extends StatefulWidget {
  static const String route = "menu/request";
  final String? idRequest;

  const AuthReqScreen({super.key, this.idRequest});

  @override
  State<AuthReqScreen> createState() => _AuthReqScreenState();
}

class _AuthReqScreenState extends State<AuthReqScreen> {
  WithReq? request;
  bool done = false;
  bool anim = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      getReq();
    });
  }

  void allow(int id) async {
    ComInterface net = ComInterface();
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/allow", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      if(mounted) Navigator.of(context).pop();
      setState(() {done = true;});
      Future.delayed(const Duration(milliseconds: 300), () => setState(() {anim = true;}));
      Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
    } catch (e) {
      debugPrint(e.toString());
      if(mounted) Navigator.of(context).pop();
      var err = json.decode(e.toString());
      await Dialogs.openAlertBox(context, "Error", err['errorMessage']);
      if(mounted) Navigator.of(context).pop();
    }
  }

  void unsure(int id) async {
    ComInterface net = ComInterface();
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/unsure", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      if(mounted) Navigator.of(context).pop();
      setState(() {done = true;});
      Future.delayed(const Duration(milliseconds: 300), () => setState(() {anim = true;}));
      Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
    } catch (e) {
      debugPrint(e.toString());
      if(mounted) Navigator.of(context).pop();
      var err = json.decode(e.toString());
      await Dialogs.openAlertBox(context, "Error", err['errorMessage']);
      if(mounted) Navigator.of(context).pop();
    }
  }

  void vote(int id, bool upvote) async {
    ComInterface net = ComInterface();
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/vote", body: {"id": id, "up": upvote}, serverType: ComInterface.serverGoAPI);
      if(mounted) Navigator.of(context).pop();
      setState(() {done = true;});
      Future.delayed(const Duration(milliseconds: 300), () => setState(() {anim = true;}));
      Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
    } catch (e) {
      debugPrint(e.toString());
      if(mounted) Navigator.of(context).pop();
      var err = json.decode(e.toString());
      await Dialogs.openAlertBox(context, "Error", err['errorMessage']);
      if(mounted) Navigator.of(context).pop();
    }
  }

  void deny(int id) async {
    ComInterface net = ComInterface();
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/deny", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      if(mounted) Navigator.of(context).pop();
      setState(() {done = true;});
      Future.delayed(const Duration(milliseconds: 300), () => setState(() {anim = true;}));
      Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
    } catch (e) {
      debugPrint(e.toString());
      if(mounted) Navigator.of(context).pop();
      var err = json.decode(e.toString());
      await Dialogs.openAlertBox(context, "Error", err['errorMessage']);
      if(mounted) Navigator.of(context).pop();
    }
  }

  void getReq() async {
    if (widget.idRequest == null) {
      Navigator.pop(context);
      return;
    }
    ComInterface com = ComInterface();
    try {
      Map<String, dynamic> m = {"id": widget.idRequest};
      var req = await com.post("/request/withdraw", body: m, serverType: ComInterface.serverGoAPI, debug: true);
      print(req.toString());
      request = WithReq.fromJson(req);
      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
      var err = json.decode(e.toString());
      await Dialogs.openAlertBox(context, "Error", err['errorMessage']);
      if(mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Text("New Withdrawal Request"),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(request?.username.toString() ?? "No username"),
                    Text("${request?.amount.toString() ?? "No amount"} XDN"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FlatCustomButton(
                  onTap: () {
                    Utils.openLink("https://xdn-explorer.com/address/${request?.address}");
                  },
                  color: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            request?.address ?? "No address",
                            maxLines: 1,
                            minFontSize: 10,
                            maxFontSize: 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.open_in_browser,
                          size: 15,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                Utils.convertDate(request?.datePosted.toString()),
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 50),
              if (request?.currentUser == false && request?.idUserVoting != 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlatCustomButton(
                    icon: const Icon(
                      Icons.thumb_up_alt_sharp,
                      color: Colors.lime,
                    ),
                    onLongPress: () {
                      vote(request!.id!, true);
                    },
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Long press to deny"),
                        duration: Duration(seconds: 2),
                      ));
                    },
                  ),
                  FlatCustomButton(
                    icon: const Icon(
                      Icons.thumb_down_alt_sharp,
                      color: Colors.red,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Long press to allow"),
                        duration: Duration(seconds: 2),
                      ));
                    },
                    onLongPress: () {
                      vote(request!.id!, false);
                    },
                  ),
                ],
              ),
              if (request?.currentUser == true && request?.idUserVoting != 0)
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlatCustomButton(
                    icon: const Icon(
                      Icons.block,
                      color: Colors.red,
                      size: 35,
                    ),
                    onLongPress: () {
                      deny(request?.id ?? 0);
                    },
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Long press to deny"),
                        duration: Duration(seconds: 2),
                      ));
                    },
                  ),
                  FlatCustomButton(
                    icon: const Icon(
                      Icons.check,
                      color: Colors.lime,
                      size: 35,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Long press to allow"),
                        duration: Duration(seconds: 2),
                      ));
                    },
                    onLongPress: () {
                      allow(request?.id ?? 0);
                    },
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Text(
                        request!.downvotes.toString(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.thumb_down_alt_sharp,
                        color: Colors.red,
                      )
                    ],
                  ),
                  const SizedBox(width: 15),
                  Column(
                    children: [
                      Text(
                        request!.upvotes.toString(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.lime, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.thumb_up_alt_sharp,
                        color: Colors.lime,
                      )
                    ],
                  ),
                ],
              ),
                if (request?.currentUser == false && request?.idUserVoting == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FlatCustomButton(
                        child: const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Icon(
                            Icons.block,
                            color: Colors.red,
                            size: 35,
                          ),
                        ),
                        onLongPress: () {
                          deny(request?.id ?? 0);
                        },
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Long press to deny"),
                            duration: Duration(seconds: 2),
                          ));
                        },
                      ),
                      FlatCustomButton(
                        child: const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Icon(
                            Icons.check,
                            color: Colors.lime,
                            size: 35,
                          ),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Long press to allow"),
                            duration: Duration(seconds: 2),
                          ));
                        },
                        onLongPress: () {
                          allow(request?.id ?? 0);
                        },
                      ),
                      FlatCustomButton(
                        child: const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Icon(
                            Icons.thumbs_up_down,
                            color: Colors.amber,
                            size: 35,
                          ),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Long press to allow"),
                            duration: Duration(seconds: 2),
                          ));
                        },
                        onLongPress: () {
                          unsure(request?.id ?? 0);
                        },
                      ),
                    ],
                  ),
            ]),
          ),
        ),
        Positioned(
          top: 50,
          left: 8,
          child: FlatCustomButton(
            radius: 8.0,
            color: Colors.black12,
            splashColor: Colors.amber,
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Padding(
              padding: EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                  SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ),
        Visibility(visible: request == null,child: Material(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator(color: Colors.white70,strokeWidth: 2.0,),)),
        ),
        ),
        Visibility(visible: done,child: Material(
          child: Container(
              color: Colors.black.withOpacity(0.2),
              child:  Center(
                child: AnimatedScale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutBack,
                scale: anim ? 1 : 0,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.lime, size: 150,),
                      Text("Success", style: TextStyle(fontSize: 30, color: Colors.white),),
                    ],
                  ),
                ),
              ),)),
        ),
        ),
      ],
    );
  }
}
