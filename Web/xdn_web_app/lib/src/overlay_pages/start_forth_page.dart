import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/provider/blocking_provider.dart';
import 'package:xdn_web_app/src/provider/mn_provider.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/extensions.dart';
import 'package:xdn_web_app/src/support/s_p.dart';
import 'package:xdn_web_app/src/support/secure_storage.dart';
import 'package:xdn_web_app/src/widgets/alert_dialogs.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';

class ForthOvrPage extends ConsumerStatefulWidget {
  const ForthOvrPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ForthOvrPage> createState() => _ForthOvrPageState();
}

class _ForthOvrPageState extends ConsumerState<ForthOvrPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isFound = true;
  bool _shouldCancel = false;
  String? _mnText;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final rr = ref.read(blockProvider.notifier);
      rr.setBlock(true);
      _controller.addListener(() {
        if (_controller.text.length >= 34) {
          _startMasternode(_controller.text);
        }
      });
    });
  }

  void _startMasternode(String address) async {
    try {
      RegExp regex = RegExp(r"^\b(d)[a-zA-Z0-9]{33}$");
      if (!regex.hasMatch(address)) {
        debugPrint("Invalid address");
        throw Exception("Invalid address");
      }
      setState(() {
        _isLoading = true;
      });
      final net = ref.read(networkProvider);
      final rr = ref.read(blockProvider.notifier);
      final rrr = ref.read(mnProvider.notifier);
      var e = await net.post("/masternode/non/start", body: {"idCoin": 0, "address": address}, serverType: ComInterface.serverGoAPI);
      setState(() {
        if (e["data"] != null) {
          _mnText = e["data"];
        } else {
          throw Exception("Error getting Masternode config");
        }
      });
      rr.setBlock(false);
      List<String> l = _mnText!.split(" ");
      rrr.setConfig(l[0]);
      rrr.setTxId(l[3]);
      await SecureStorage.write(key: "mn", value: _mnText!);
      setState(() {
        _isLoading = false;
        _isFound = true;
        _shouldCancel = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _controller.clear();
      try {
        var err = json.decode(e.toString());
        if (err['errorMessage'] == "address not found." && _shouldCancel == false) {
          Future.delayed(const Duration(seconds: 5), () {
            setState(() {
              _isFound = false;
            });
          });
          _startMasternode(address);
          return;
        } else if (err['errorMessage'] == "address not found." && _shouldCancel == true) {
          setState(() {
            _isFound = true;
            _shouldCancel = false;
          });
          showAlertDialog(context: context, title: "Error", content: "Address not found, please try again later");
          return;
        }
        showAlertDialog(context: context, title: "Error", content: err['errorMessage']);
      } catch (e) {
        var ee = e.toString();
        try {
          var err = e.toString().split("Exception:")[2].replaceAll("^", "");
          showAlertDialog(context: context, title: "Error", content: err);
        } catch (e) {
          showAlertDialog(context: context, title: "Error", content: ee.toString());
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        gapH20,
        const Text(
          'Step 3',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 24.0),
        ),
        gapH12,
        if (_mnText == null && _isLoading && _isFound)
          const Expanded(
              child: Center(
                  child: CircularProgressIndicator(
            color: Colors.white70,
          ))),
        if (_mnText == null && _isLoading && !_isFound)
          Expanded(
              child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(
                color: Colors.white70,
              ),
              gapH24,
              const Text(
                "Address could not be found",
                style: TextStyle(color: Colors.white70, fontSize: 20.0),
              ),
              gapH8,
              const Text(
                "Please wait until address appears on blockchain",
                style: TextStyle(color: Colors.white70, fontSize: 12.0),
              ),
              gapH8,
              const Text(
                "This could take up to 10 minutes, after transaction has been sent",
                style: TextStyle(color: Colors.white70, fontSize: 10.0),
              ),
              gapH20,
              FlatCustomButton(
                  height: 30,
                  width: 200,
                  radius: 8.0,
                  color: Colors.pinkAccent,
                  splashColor: Colors.red,
                  onTap: () {
                    setState(() {
                      _shouldCancel = true;
                    });
                  },
                  child: AutoSizeText(
                    "Cancel address lookup",
                    maxLines: 1,
                    minFontSize: 8.0,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70, fontSize: 14.0),
                  )),
            ]),
          )),
        if (_mnText == null && !_isLoading)
          Column(
            children: [
              gapH24,
              const Text(
                'Enter XDN address which you generated in previous step',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14.0),
              ),
              gapH32,
              gapH8,
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.black12,
                    border: OutlineInputBorder(),
                    labelText: 'Enter your XDN address',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        if (_mnText != null)
          Column(
            children: [
              gapH24,
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AutoSizeText.selectable(
                        _mnText!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        minFontSize: 8.0,
                        style: const TextStyle(color: Colors.white70, fontSize: 18.0),
                      ),
                    ),
                    FlatCustomButton(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _mnText));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Copied to clipboard'),
                          backgroundColor: Colors.lightGreen,
                        ));
                      },
                      radius: 8,
                      color: Colors.transparent,
                      splashColor: Colors.green,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.copy, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              gapH16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "1) Open".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                  ),
                  SelectableText(
                    " masternode.conf ".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              gapH16,
              SizedBox(width: MediaQuery.of(context).size.width * 0.5, child: Image.asset("assets/images/start_mn5.png")),
              gapH12,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "If it does not exist, create new file called ".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 10.0),
                  ),
                  SelectableText(
                    "masternode.conf ".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "inside XDN data directory".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 10.0),
                  ),
                ],
              ),
              gapH24,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "2) Paste MN config from field above on new line in".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                  ),
                  SelectableText(
                    " masternode.conf ".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              gapH12,
              SizedBox(width: MediaQuery.of(context).size.width * 0.5, child: Image.asset("assets/images/start_mn_conf.png")),
              gapH12,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "3) Save, close and proceed to next step".hardcoded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
