import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/screens/main_menu.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/get_info.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:digitalnote/globals.dart' as globals;
import 'package:digitalnote/screens/registerscreen.dart';
import 'package:digitalnote/support/Encrypt.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:styled_text/styled_text.dart';

import '../support/ColorScheme.dart';
import '../support/Dialogs.dart';

const serverIP = globals.SERVER_URL;

class LoginPage extends StatefulWidget {
  static const String route = "/login";

  const LoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? login;
  String? pass;
  var rr = false;
  GetInfo? getInfo;

  void _checkSendEmail(String nickname) {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    _attemptResetPass(nickname);
  }

  @override
  void initState() {
    super.initState();
    _getInfoGet();
  }

  _getInfoGet() async {
    getInfo = await NetInterface.getInfo();
    setState((){});
  }

  Future<String?> _attemptResetPass(String nickname) async {
    var res = await http.post(Uri.parse("$serverIP/forgotPass"), headers: {
      "username": nickname,
    }).timeout(const Duration(seconds: 10));

    if (res.contentLength == 0) {
      if (mounted) {
        Navigator.of(context).pop();
        Dialogs.openAlertBox(context, "Failure!", "There is an issue with service, please try again later");
      }
      return null;
    }

    if (res.statusCode == 200) {
      if (mounted) {
        Navigator.of(context).pop();
        Dialogs.openAlertBox(context, "Success!", "Your new password has been sent to your e-mail");
      }
      return res.body;
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        Dialogs.openAlertBox(context, "Failure!", "There are no matching credentials in DigitalNote database");
      }
      return null;
    }
  }

  Future<void> attemptLogIn(BuildContext context, String username, String password, {String? pin}) async {
    login = username;
    pass = password;
    try {
      Dialogs.openWaitBox(context);
      Map<String, dynamic> m = {
        "username": username,
        "password": password,
      };
      if (pin != null) {
        m['twoFactor'] = pin;
      }
      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      var res = await http.post(Uri.parse("$serverIP/login"), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (res.contentLength == 0) {
        if (mounted) {
          Navigator.of(context).pop();
          Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error_occur, "No response from server");
        }
        return;
      }

      if (res.statusCode == 200) {
        var data = decryptAESCryptoJS(res.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        Map<String, dynamic> r = json.decode(data);

        var username = r["username"];
        var addr = r["addr"];
        var jwt = r["jwt"];
        var userID = r["userid"];
        var adminPriv = r["admin"];
        var nickname = r["nickname"];

        SecureStorage.write(key: globals.USERNAME, value: username);
        SecureStorage.write(key: globals.ADR, value: addr);
        SecureStorage.write(key: globals.ID, value: userID.toString());
        SecureStorage.write(key: globals.TOKEN, value: jwt);
        SecureStorage.write(key: globals.ADMINPRIV, value: adminPriv.toString());
        SecureStorage.write(key: globals.NICKNAME, value: nickname.toString());

        String udid = await FlutterUdid.consistentUdid;
        SecureStorage.write(key: globals.UDID, value: udid);
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamedAndRemoveUntil(MainMenuNew.route, (Route<dynamic> route) => false);
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuScreen()));
        } else {
          if (mounted) {
            Navigator.of(context).pop();
            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error_occur, jwt['message']);
          }
        }
      } else if (res.statusCode == 409) {
        if (mounted) Dialogs.open2FABox(context, _auth2FA);
      } else {
        if (mounted) {
          var data = decryptAESCryptoJS(res.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
          var error = '';
          if (data.toString() == 'User does not exists') {
            error = AppLocalizations.of(context)!.user_not_exists;
          } else {
            error = data.toString();
          }
          Navigator.of(context).pop();
          Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error_occur, error);
        }
        return;
      }
    } on TimeoutException catch (_) {
      // Map<String, dynamic> m = {
      //   "error": true,
      //   "message": "No response from server",
      // };
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error_occur, "No response from server");
      return;
    } on SocketException catch (_) {
      // Map<String, dynamic> m = {
      //   "error": true,
      //   "message": "No response from server",
      // };
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error_occur, "No response from server");
      return;
    } catch (e) {
      var error = '';
      if (e.toString().trim() == 'Bad login details/2FA code') {
        error = AppLocalizations.of(context)!.user_not_exists;
      } else {
        error = e.toString();
      }
      // Map<String, dynamic> m = {
      //   "error": true,
      //   "message": error,
      // };
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error_occur, error);
      return;
    }
  }

  _auth2FA(String? s) async {
    if (!rr) {
      rr = true;
      attemptLogIn(context, login!, pass!, pin: s!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    return Stack(
      children: [
        const BackgroundWidget(
          hasImage: false,
          image: "",
        ),
        SafeArea(
            child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 320,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: Colors.black12,
                    ),
                    child: const Center(
                      child: Image(
                        image: AssetImage('images/logo.png'),
                        color: Colors.white70,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        )),
        Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            child: GestureDetector(
              onTap: () {
                Dialogs.openForgotPasswordBox(context, _checkSendEmail);
              },
              child: Text(
                AppLocalizations.of(context)!.forgot_pass,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontStyle: FontStyle.normal, fontWeight: FontWeight.w400, color: Colors.white38, fontSize: 16.0),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Container(
                    color: const Color(0xFF22283A).withOpacity(0.5),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
                            child: TextField(
                              controller: _usernameController,
                              autofillHints: const [AutofillHints.username],
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9@._-\s]+')),
                              ],
                              decoration: InputDecoration(
                                fillColor: Colors.black26,
                                filled: true,
                                hintText: "${AppLocalizations.of(context)!.username} | ${AppLocalizations.of(context)!.email}",
                                hintStyle: Theme.of(context).textTheme.subtitle1,
                                contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white, width: 1.0), borderRadius: BorderRadius.circular(10.0)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white30, width: 0.5), borderRadius: BorderRadius.circular(10.0)),
                                border: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(10.0)),
                              ),
                              style: Theme.of(context).textTheme.bodyText2,
                              onEditingComplete: () {},
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
                            child: TextField(
                              controller: _passwordController,
                              autofillHints: const [AutofillHints.password],
                              onEditingComplete: () => TextInput.finishAutofillContext(shouldSave: true),
                              obscureText: true,
                              decoration: InputDecoration(
                                fillColor: Colors.black26,
                                filled: true,
                                hintText: AppLocalizations.of(context)!.password,
                                hintStyle: Theme.of(context).textTheme.subtitle1,
                                contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white, width: 1.0), borderRadius: BorderRadius.circular(10.0)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white30, width: 0.5), borderRadius: BorderRadius.circular(10.0)),
                                border: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(10.0)),
                              ),
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                          ),
                          const SizedBox(
                            height: 15.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0, left: 50.0, right: 50.0),
                            child: SizedBox(
                              width: 150,
                              height: 40,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                                child: Material(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)),
                                  color: Colors.white,
                                  child: InkWell(
                                      splashColor: Theme.of(context).konjCardColor,
                                      onTap: () async {
                                        var username = _usernameController.text;
                                        var password = _passwordController.text;
                                        if (username.isEmpty || password.isEmpty) {
                                          Dialogs.openAlertBox(
                                              context, AppLocalizations.of(context)!.warning, AppLocalizations.of(context)!.fields_cant_empty);
                                          return;
                                        }
                                        attemptLogIn(context, username, password);
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.only(top: 0.0),
                                          child: Text(AppLocalizations.of(context)!.log_in,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.black)))),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          Padding(
                              padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
                              child: SizedBox(
                                width: 150,
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                                    child: Material(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)),
                                        color: Colors.black26,
                                        child: InkWell(
                                            splashColor: Theme.of(context).konjCardColor,
                                            onTap: () async {
                                              Navigator.push(context, CupertinoPageRoute<bool>(builder: (context) => const RegisterScreen()));
                                            },
                                            child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Text(AppLocalizations.of(context)!.sign_up,
                                                    textAlign: TextAlign.center,
                                                    style:
                                                        Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70, fontSize: 14.0)))))),
                              )),
                          Container(
                            width: 85,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white10),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 2.0, bottom: 2.0),
                              child: Row(
                                children: [
                                  AutoSizeText(
                                    "Server status",
                                    style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                    minFontSize: 2.0,
                                  ),
                                  const SizedBox(
                                    width: 5.0,
                                  ),
                                  Icon(
                                    Icons.circle,
                                    size: 10.0,
                                    color: getInfo != null ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0,)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
