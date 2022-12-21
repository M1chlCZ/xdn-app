import 'package:digitalnote/screens/screen_lock.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:digitalnote/globals.dart' as globals;



class AuthScreen extends StatefulWidget {
  static const String route = "/auth";
  final bool setupPIN;
  final int type;
  final Function(bool)? callback;

  const AuthScreen({Key? key, this.setupPIN = false, this.type = 0, this.callback})
      : super(key: key);

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
   

  List<int> _tempPIN = [];
  List<int> _tempPIN2 = [];

  bool _isFingerprint = false;
  bool _firstPIN = true;
  bool _showFinger = false;

  List<int> _myPass = [];

  @override
  void initState() {
    _getPIN();
    _getAuthType();
    super.initState();
    Future.delayed(Duration.zero).then((_) async {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });

  }

  void _getPIN() async {
    String? nums = await  SecureStorage.read(key: globals.PIN);
    if (nums == null) return;
    _myPass = nums.split('').map(int.parse).toList();
  }

  void _getAuthType() async {
    if (widget.setupPIN != true) {
      String? i = await  SecureStorage.read(key: globals.AUTH_TYPE);
      if (i == null || int.parse(i) == 0) {
        setState(() {
          _showFinger = false;
        });
      } else if (int.parse(i) == 1) {
        try {
          biometrics();
        } catch (e) {
          setState(() {
            _showFinger = true;
          });
        }
      } else {
        setState(() {
          _showFinger = true;
        });
      }
    }
  }

  Future<void> biometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool authenticated = false;

    try {
      authenticated = await auth.authenticate(
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
            sensitiveTransaction: true,
            biometricOnly: true,
          ),
          localizedReason: 'Scan your fingerprint to authenticate',);
    } on PlatformException catch (e) {
      setState(() {
        _showFinger = false;
      });
      debugPrint(e.toString());
    }
    if (!mounted) return;
    if (authenticated) {
      setState(() {
        _isFingerprint = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Visibility(
        visible: !widget.setupPIN,
        child: IgnorePointer(
          ignoring: widget.setupPIN,
          child: Material(
            child: SafeArea(
                child: LockScreen(
                    title: AppLocalizations.of(context)!.pin_enter,
                    passLength: 4,
                    numColor: Colors.white70,
                    bgImage: "images/pending_rocket_pin.png",
                    fingerPrintImage: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(colors: [
                          Color(0xFF313C5D),
                          Color(0xFF4A5EB0),
                        ]).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Image.asset(
                        "assets/images/fingerprint.png",
                        height: 50.0,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    showFingerPass: _showFinger,
                    fingerFunction: biometrics,
                    fingerVerify: _isFingerprint,
                    borderColor: Colors.white,
                    showWrongPassDialog: false,
                    wrongPassContent:
                        AppLocalizations.of(context)!.error,
                    wrongPassTitle: "Opps!",
                    wrongPassCancelButtonText: "Cancel",
                    passCodeVerify: (passcode) async {
                      for (int i = 0; i < _myPass.length; i++) {
                        if (passcode[i] != _myPass[i]) {
                          return false;
                        }
                      }

                      return true;
                    },
                    onSuccess: () {
                      if (widget.type == 0) {
                        Navigator.of(context).pushNamedAndRemoveUntil("menu", (Route<dynamic> route) => false);
                        // Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder:
                        //     (BuildContext context, _, __) {
                        //   return const MainMenuScreen();
                        // }, transitionsBuilder:
                        //     (_, Animation<double> animation, __, Widget child) {
                        //   return FadeTransition(
                        //       opacity: animation, child: child);
                        // }));
                      } else if (widget.type == 2) {
                        widget.callback == null ? Navigator.of(context).pop(true) : widget.callback!(true);
                      } else {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed("menu/settings/security");
                      //   Navigator.of(context).push(PageRouteBuilder(pageBuilder:
                      //       (BuildContext context, _, __) {
                      //     return const SecurityScreen();
                      //   }, transitionsBuilder:
                      //       (_, Animation<double> animation, __, Widget child) {
                      //     return FadeTransition(
                      //         opacity: animation, child: child);
                      //   }));
                      }
                    })),
          ),
        ),
      ),
      Visibility(
        visible: widget.setupPIN,
        child: IgnorePointer(
          ignoring: !widget.setupPIN,
          child: Material(
            child: SafeArea(
                child: Stack(
              children: [
                Visibility(
                    visible: _firstPIN,
                    child: IgnorePointer(
                      ignoring: !_firstPIN,
                      child: LockScreen(
                          title: AppLocalizations.of(context)!.set_pin,
                          passLength: 4,
                          numColor: Colors.white70,
                          bgImage: "images/pending_rocket_pin.png",
                          fingerPrintImage: null,
                          showFingerPass: false,
                          fingerFunction: biometrics,
                          fingerVerify: _isFingerprint,
                          borderColor: Colors.white,
                          showWrongPassDialog: false,
                          wrongPassContent: "",
                          wrongPassTitle: "",
                          wrongPassCancelButtonText: "Cancel",
                          passCodeVerify: (passcode) async {
                            if (passcode.length != 4) {
                              return false;
                            }
                            _tempPIN = passcode;
                            return true;
                          },
                          onSuccess: () {
                            setState(() {
                              _firstPIN = false;
                            });
                          }),
                    )),
                Visibility(
                    visible: !_firstPIN,
                    child: IgnorePointer(
                      ignoring: _firstPIN,
                      child: LockScreen(
                          title: AppLocalizations.of(context)!.set_pin_confirm,
                          passLength: 4,
                          numColor: Colors.white70,
                          bgImage: "images/pending_rocket_pin.png",
                          fingerPrintImage: null,
                          showFingerPass: false,
                          fingerFunction: biometrics,
                          fingerVerify: _isFingerprint,
                          borderColor: Colors.white,
                          showWrongPassDialog: false,
                          wrongPassContent: "",
                          wrongPassTitle: "",
                          wrongPassCancelButtonText: "Cancel",
                          passCodeVerify: (passcode) async {
                            if (passcode.length != 4) {
                              return false;
                            }
                            _tempPIN2 = passcode;
                            return true;
                          },
                          onSuccess: () {
                            _checkSetupPIN();
                          }),
                    )),
                Container(
                  margin: const EdgeInsets.only(top: 80.0, left: 20.0),
                  child: SizedBox.fromSize(
                    size: const Size(40, 40), // labelLarge width and height

                    child: ClipOval(
                      child: Material(
                        color: Colors.black12, // labelLarge color
                        child: InkWell(
                          splashColor: Colors.white.withOpacity(0.8), // splash color
                          onTap: () {
                            SecureStorage.deleteStorage(key:"PIN");
                            Navigator.pop(context);
                          }, // labelLarge pressed
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const <Widget>[
                              Icon(Icons.close, color: Colors.white70,),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )),
          ),
        ),
      ),
      Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 0.0),
            child: SizedBox(
                width: 180,
                height: 100,
                child: Image.asset("images/logo.png", color: Colors.white70,)),
          ),
        ),
      ),
    ]);
  }

  void _checkSetupPIN() async {
    String first = _tempPIN.map((i) => i.toString()).join("");
    String second = _tempPIN2.map((i) => i.toString()).join("");
    var succ = false;
    if (first == second) {
      succ = true;
       SecureStorage.write(key: globals.PIN, value: first.toString());
    }else{
      _tempPIN.clear();
      _tempPIN2.clear();
      setState(() {
        _firstPIN = true;
      });
    }
    if(widget.type == 2) {
      Navigator.of(context).pushReplacementNamed("menu");
    }else {
      Navigator.of(context).pop(succ);
    }
  }
}
