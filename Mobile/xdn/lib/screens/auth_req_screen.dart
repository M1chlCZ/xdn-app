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

  const AuthReqScreen({Key? key, this.idRequest}) : super(key: key);

  @override
  State<AuthReqScreen> createState() => _AuthReqScreenState();
}

class _AuthReqScreenState extends State<AuthReqScreen> {
  WithReq? request;
  bool done = false;

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
      await net.post("/request/allow", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      done = true;
      setState(() {});
      Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
    } catch (e) {
      Dialogs.openAlertBox(context, "Error", e.toString());
      print(e);
    }
  }

  void deny(int id) async {
    ComInterface net = ComInterface();
    try {
      await net.post("/request/deny", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      done = true;
      setState(() {});
      Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
    } catch (e) {
      Dialogs.openAlertBox(context, "Error", e.toString());
      print(e);
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
      request = WithReq.fromJson(req);
      setState(() {});
    } catch (e) {
      Dialogs.openAlertBox(context, "Error", e.toString());
      print(e);
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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Text("New Withdrawal Request"),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(request?.request?.username.toString() ?? "No username"),
                    Text("${request?.request?.amount.toString() ?? "No amount"} XDN"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FlatCustomButton(
                  onTap: () {
                    Utils.openLink("https://xdn-explorer.com/address/${request?.request?.address}");
                  },
                  color: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            request?.request?.address ?? "No address",
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
                Utils.convertDate(request?.request?.datePosted.toString()) ?? "No date",
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 50),
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
                      deny(request?.request?.id ?? 0);
                    },
                    onTap: () {
                      ScaffoldMessenger.of(context)!.showSnackBar(const SnackBar(
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
                      ScaffoldMessenger.of(context)!.showSnackBar(const SnackBar(
                        content: Text("Long press to allow"),
                        duration: Duration(seconds: 2),
                      ));
                    },
                    onLongPress: () {
                      allow(request?.request?.id ?? 0);
                    },
                  ),
                ],
              ),
            ]),
          ),
        ),
        Positioned(
          top: 85,
          left: 5,
          child: FlatCustomButton(
            radius: 8.0,
            color: Colors.black12,
            splashColor: Colors.amber,
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: const [
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
              child:  Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.check, color: Colors.lime, size: 150,),
                  Text("Success", style: TextStyle(fontSize: 30, color: Colors.white),),
                ],
              ),)),
        ),
        ),
      ],
    );
  }
}
