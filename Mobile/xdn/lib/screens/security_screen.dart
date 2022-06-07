import 'dart:io';


import 'package:digitalnote/screens/auth_screen.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:digitalnote/globals.dart' as globals;
import 'package:flutter_biometrics/flutter_biometrics.dart';

import '../widgets/button_neu.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  SecurityScreenState createState() => SecurityScreenState();
}

class SecurityScreenState extends State<SecurityScreen> {
   
  var firstValue = false;
  var secondValue = true;

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
  }

  _getBiometrics() async {
    try {
      if (Platform.isIOS) {
        _biometrics = await FlutterBiometrics.availableBiometrics;
        _dropValues.clear();
        if (_biometrics != null && _biometrics != "nothing") {
          _dropValues.add('PIN');
          _dropValues.add(_biometrics!);
          _dropValues.add("PIN + " + _biometrics!);
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
    String? auth = await  SecureStorage.read(key: globals.AUTH_TYPE);
    Future.delayed(Duration.zero, () {
      setState(() {
        _dropValue = _dropValues[int.parse(auth!)];
      });
    });
  }

  // void _getCreds() async {
  //   String? login = await  SecureStorage.read(key: globals.LOGIN);
  //   String? pass = await  SecureStorage.read(key: globals.PASS);
  //
  //   if (login != null && pass != null) {
  //     setState(() {
  //       _creds = true;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: const Padding(
              padding: EdgeInsets.all(15.0),
              child: Icon(
                Icons.arrow_back_ios,
                size: 30.0,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: const Color(0x00181A21),
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: SizedBox(
                height: 20,
                child: Image.asset(
                  'assets/images/exb_header.png',
                  fit: BoxFit.fitWidth,
                  scale: 2.5,
                )),
          ),
        ),
      ),
      body: Material(
        child: SafeArea(
          child: Stack(
            children: [
              Column(children: [
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
                          "Security",
                          textAlign: TextAlign.start,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(fontSize: 14.0, color: Colors.white24),
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
                            Text("Authentication type",
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4!
                                    .copyWith(
                                        fontSize: 14.0, color: Colors.white)),
                            // SizedBox(
                            //   width: MediaQuery.of(context).size.width * 0.4,
                            // ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 80.0, right: 8.0),
                                child: SizedBox(
                                  height: 30,
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
                                        items: _dropValues
                                            .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: SizedBox(
                                                    width: 70,
                                                    child: Text(e))))
                                            .toList(),
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
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(fontSize: 14.0, color: Colors.white24),
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
                        SizedBox(
                          height: 50.0,
                          child: Card(
                              elevation: 0,
                              color: Theme.of(context).canvasColor,
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0.0),
                              ),
                              child: InkWell(
                                splashColor: Colors.black54,
                                highlightColor: Colors.black54,
                                onTap: () async {
                                  _changePIN();
                                },
                                // widget.coinSwitch(widget.coin);
                                // widget.activeCoin(widget.coin.coin!);

                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                        "Change PIN",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4!
                                            .copyWith(
                                                fontSize: 14.0,
                                                color: Colors.white)),
                                    const Expanded(
                                      child: SizedBox(),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 10.0),
                                      child: NeuButton(
                                          height: 25,
                                          width: 20,
                                          onTap: () async {
                                            _removePIN();
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
                        const SizedBox(
                          height: 10.0,
                        ),
                        SizedBox(
                          height: 50.0,
                          child: Card(
                              elevation: 0,
                              color: Theme.of(context).canvasColor,
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0.0),
                              ),
                              child: InkWell(
                                splashColor: Colors.black54,
                                highlightColor: Colors.black54,
                                onTap: () async {
                                  Dialogs.openGenericAlertBox(context, message: "Remove PIN", onTap: _removePIN, oneButton: false);
                                },
                               child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                        "Remove PIN",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4!
                                            .copyWith(
                                                fontSize: 14.0,
                                                color: Colors.white)),
                                    const Expanded(
                                      child: SizedBox(),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 10.0),
                                      child: NeuButton(
                                          height: 25,
                                          width: 20,
                                          onTap: () async {
                                            Dialogs.openGenericAlertBox(context, message: "Remove PIN", onTap: _removePIN, oneButton: false);
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
              ])
            ],
          ),
        ),
      ),
    );
  }

  void _removePIN() {
    Navigator.of(context).pop();
    Navigator.of(context)
        .push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
          return AuthScreen(
            type: 2,
            callback: _removePINCallback,
          );
        }, transitionsBuilder:
            (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        }));
  }

  void _removePINCallback(bool b) async {
    if (b == true) {
       SecureStorage.deleteStorage(key: globals.PIN);
      await Future.delayed(const Duration(milliseconds: 200), () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: SizedBox(
              height: 40.0,
              child: Center(
                  child: Text("PIN remove"))),
          backgroundColor: Colors.green,
        ));
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      });
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: SizedBox(
            height: 40.0,
            child: Center(
                child: Text("PIN remove error"))),
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
        }, transitionsBuilder:
            (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        }))
        .then((value) => _changePINCallback(value));
  }

  void _changePINCallback(bool? b) {
    if (b == null || b == false) return;
    Navigator.of(context)
        .push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
          return const AuthScreen(setupPIN: true);
        }, transitionsBuilder:
            (_, Animation<double> animation, __, Widget child) {
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
        content: SizedBox(
            height: 40.0,
            child: Center(
                child: Text(_state
                    ? "PIN change successful"
                    : "PIN change unsuccessful"))),
        backgroundColor: _state ? Colors.green : Colors.red,
      ));
    });
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
