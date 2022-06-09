import 'dart:io';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:digitalnote/screens/auth_screen.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:digitalnote/globals.dart' as globals;
import 'package:flutter_biometrics/flutter_biometrics.dart';
import 'package:requests/requests.dart';

import '../widgets/button_neu.dart';

class SecurityScreen extends StatefulWidget {
  static const String route = "/menu/settings/security";

  const SecurityScreen({Key? key}) : super(key: key);

  @override
  SecurityScreenState createState() => SecurityScreenState();
}

class SecurityScreenState extends State<SecurityScreen> {
  var firstValue = false;
  var secondValue = true;
  var twoFactor = false;
  var settingUP = false;
  var run = false;

  String? _biometrics;
  String _dropValue = 'PIN';
  final List<String> _dropValues = ['PIN'];

  @override
  void initState() {
    super.initState();
    _initBio();
    // _getCreds();
  }

  _initBio() async {
    await _getBiometrics();
    await _getAuthType();
    await _getTwoFactor();
  }

  _getBiometrics() async {
    try {
      if (Platform.isIOS) {
        _biometrics = await FlutterBiometrics.availableBiometrics;
        _dropValues.clear();
        if (_biometrics != null && _biometrics != "nothing") {
          _dropValues.add('PIN');
          _dropValues.add(_biometrics!);
          _dropValues.add("PIN + ${_biometrics!}");
        } else {
          _dropValues.add('PIN');
        }
      } else {
        _dropValues.clear();
        _dropValues.add('PIN');
        _dropValues.add("Fingerprint");
        _dropValues.add("PIN + Fingerprint");
      }
      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _getAuthType() async {
    String? auth = await SecureStorage.read(key: globals.AUTH_TYPE);
    Future.delayed(Duration.zero, () {
      setState(() {
        _dropValue = _dropValues[int.parse(auth!)];
      });
    });
  }

  _getTwoFactor() async {
    try {
      ComInterface ci = ComInterface();
      String? id = await SecureStorage.read(key: globals.ID);
      Map<String, dynamic> m = await ci.get("/data", request: {"id": id!, "request": "twofactorCheck"});
      Future.delayed(Duration.zero, () {
        setState(() {
          twoFactor = m['twoFactor'] == 1 ? true : false;
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  // _getPin() async {
  //   String? pin = await  SecureStorage.read(key: globals.PIN);
  //   if (pin != null && pin.isNotEmpty) {
  //     Future.delayed(Duration.zero, () {
  //       setState(() {
  //         pinUsed = true;
  //       });
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: Stack(
          children: [
            const BackgroundWidget(),
            SafeArea(
              child: Column(children: [
                const Header(header: "Security"),
                const SizedBox(
                  height: 20.0,
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Security",
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.subtitle1!.copyWith(fontSize: 14.0, color: Colors.white54),
                        ),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          height: 0.5,
                          color: Colors.white12,
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("Authentication type", style: Theme.of(context).textTheme.headline4!.copyWith(fontSize: 14.0, color: Colors.white)),
                            // SizedBox(
                            //   width: MediaQuery.of(context).size.width * 0.4,
                            // ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 80.0, right: 8.0),
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).canvasColor.withOpacity(0.8),
                                      borderRadius: const BorderRadius.all(Radius.circular(5.0))),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _dropValue,
                                        isDense: true,
                                        onChanged: (String? val) {
                                          setState(() {
                                            _dropValue = val!;
                                          });
                                          int index = _dropValues.indexWhere((values) => values.contains(val!));
                                          SecureStorage.write(key: globals.AUTH_TYPE, value: index.toString());
                                        },
                                        items:
                                            _dropValues.map((e) => DropdownMenuItem(value: e, child: SizedBox(width: 70, child: Text(e)))).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
                const SizedBox(
                  height: 40.0,
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PIN settings",
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.subtitle1!.copyWith(fontSize: 14.0, color: Colors.white54),
                        ),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          height: 0.5,
                          color: Colors.white12,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        SizedBox(
                          height: 50.0,
                          child: Card(
                              elevation: 0,
                              color: Theme.of(context).canvasColor.withOpacity(0.8),
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: InkWell(
                                splashColor: Colors.black54,
                                highlightColor: Colors.black54,
                                onTap: () async {
                                  Dialogs.openGenericAlertBox(context, message: "Really want to remove PIN?", onTap: _removePIN, oneButton: false);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 10.0),
                                    Text("Remove PIN", style: Theme.of(context).textTheme.headline4!.copyWith(fontSize: 14.0, color: Colors.white)),
                                    const Expanded(
                                      child: SizedBox(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10.0),
                                      child: NeuButton(
                                          height: 25,
                                          width: 20,
                                          color: Colors.black26,
                                          onTap: () async {
                                            Dialogs.openGenericAlertBox(context,
                                                message: "Really want to remove PIN?", onTap: _removePIN, oneButton: false);
                                          },
                                          child: const Icon(
                                            Icons.arrow_forward_ios_sharp,
                                            color: Colors.white,
                                            size: 22.0,
                                          )),
                                    )
                                  ],
                                ),
                              )),
                        ),
                      ],
                    )),
                const SizedBox(
                  height: 40.0,
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "2FA settings",
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.subtitle1!.copyWith(fontSize: 14.0, color: Colors.white54),
                        ),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          height: 0.5,
                          color: Colors.white12,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        SizedBox(
                          height: 50.0,
                          child: Card(
                              elevation: 0,
                              color: Theme.of(context).canvasColor.withOpacity(0.8),
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: InkWell(
                                splashColor: Colors.black54,
                                highlightColor: Colors.black54,
                                onTap: () {
                                  if (twoFactor) {
                                    Dialogs.open2FABox(context, _unset2FA);
                                  } else {
                                    _get2FACode();
                                  }
                                  // Dialogs.openGenericAlertBox(context, message: "Really want to remove PIN?", onTap: _removePIN, oneButton: false);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 10.0),
                                    Text(twoFactor ? "Remove 2FA" : "Set 2FA", //TODO 2FA
                                        style: Theme.of(context).textTheme.headline4!.copyWith(fontSize: 14.0, color: Colors.white)),
                                    const Expanded(
                                      child: SizedBox(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10.0),
                                      child: NeuButton(
                                          height: 25,
                                          width: 20,
                                          color: Colors.black26,
                                          onTap: () {
                                            if (twoFactor) {
                                              Dialogs.open2FABox(context, _unset2FA);
                                            } else {
                                              _get2FACode();
                                            }
                                          },
                                          child: const Icon(
                                            Icons.arrow_forward_ios_sharp,
                                            color: Colors.white,
                                            size: 22.0,
                                          )),
                                    )
                                  ],
                                ),
                              )),
                        ),
                      ],
                    ))
              ]),
            )
          ],
        ),
      ),
    );
  }

  void _removePIN() {
    Navigator.of(context).pop();
    Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
      return AuthScreen(
        type: 2,
        callback: _removePINCallback,
      );
    }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    }));
  }

  void _removePINCallback(bool b) async {
    if (b == true) {
      SecureStorage.deleteStorage(key: globals.PIN);
      await Future.delayed(const Duration(milliseconds: 200), () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: SizedBox(height: 40.0, child: Center(child: Text("PIN remove"))),
          backgroundColor: Colors.green,
        ));
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: SizedBox(height: 40.0, child: Center(child: Text("PIN remove error"))),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _changePIN() {
    Navigator.of(context)
        .push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
          return const AuthScreen(
            type: 2,
          );
        }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        }))
        .then((value) => _changePINCallback(value));
  }

  void _changePINCallback(bool? b) {
    if (b == null || b == false) return;
    Navigator.of(context)
        .push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
          return const AuthScreen(setupPIN: true);
        }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        }))
        .then((value) => _changeSucc(value));
  }

  void _changeSucc(bool? b) async {
    bool _state = false;
    if (b != null || b != false) {
      _state = true;
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: SizedBox(height: 40.0, child: Center(child: Text(_state ? "PIN change successful" : "PIN change unsuccessful"))),
        backgroundColor: _state ? Colors.green : Colors.red,
      ));
    });
  }

  _get2FACode() async {
    ComInterface cm = ComInterface();
    try {
      var id = await SecureStorage.read(key: globals.ID);
      Map<String, dynamic> m = {"request": "twofactor", "id": id};
      var req = await cm.get("/data", request: m);

      _set2FA(req['secret']);
    } catch (e) {
      Dialogs.openAlertBox(context, "Error", "2FA already turned on");
      print(e);
    }
  }

  _set2FA(String code) async {
    Dialogs.open2FASetBox(context, code, _confirm2FA);
  }

  _confirm2FA(String? s) async {
    if (!run) {
      ComInterface cm = ComInterface();
      run = true;
      try {
        var id = await SecureStorage.read(key: globals.ID);
        Map<String, dynamic> m = {"request": "twofactorValidate", "id": id, "param1": s!};
        var req = await cm.get("/data", request: m, debug: true);
        if (req['status'] == 'ok') {
          if (mounted) Navigator.of(context).pop();
          Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, "2FA activated");
        }
      } catch (e) {
        print(e);
      }
    }
    run = false;
  }

  _unset2FA(String? s) async {
    if (settingUP) {
      return;
    } else {
      settingUP = true;
    }
    Navigator.of(context).pop();
    try {
      ComInterface cm = ComInterface();
      var id = await SecureStorage.read(key: globals.ID);
      var m = {"id": id!, "param1": s, "request": "twofactorRemove"};
      Response response = await cm.get('/data', typeContent: ComInterface.typePlain, request: m);
      if (response.statusCode == 200) {
        setState(() {
          twoFactor = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "2FA disabled",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "2FA disable error",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    settingUP = false;
  }

// _removeCredentials() {
//   Dialogs.openGenericAlertBox(context, oneButton: false, message: AppLocalizations.of(context)!.sc_remove_cred, onTap:_removeCredConfirm );
// }
//
// _removeCredConfirm()async {
//   Navigator.of(context).pop();
//   await  SecureStorage.deleteStorage(key: globals.LOGIN);
//   await  SecureStorage.deleteStorage(key: globals.PASS);
//   setState(() {
//     _creds = false;
//   });
// }

}
