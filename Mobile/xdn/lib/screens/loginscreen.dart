import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:konjungate/globals.dart' as globals;
import 'package:konjungate/screens/mainMenuScreen.dart';
import 'package:konjungate/screens/registerscreen.dart';
import 'package:konjungate/support/Encrypt.dart';
import 'package:konjungate/widgets/BackgroundWidget.dart';
import 'package:styled_text/styled_text.dart';

import '../support/ColorScheme.dart';
import '../support/Dialogs.dart';

const SERVER_IP = globals.SERVER_URL;
const storage = FlutterSecureStorage();

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _checkSendEmail(String nickname) {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    _attemptResetPass(nickname);
  }

  Future<String?> _attemptResetPass(String nickname) async {
    var res = await http.post(Uri.parse("$SERVER_IP/forgotPass"), headers: {
      "username": nickname,
    }).timeout(const Duration(seconds: 10));

    if (res.contentLength == 0) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, "Failure!",
          "There is an issue with service, please try again later");
      return null;
    }

    if (res.statusCode == 200) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, "Success!",
          "Your new password has been sent to your e-mail");
      return res.body;
    } else {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, "Failure!",
          "There are no matching credentials in KONJUNGATE database");
      return null;
    }
  }

  Future<Map> attemptLogIn(BuildContext context, String username, String password) async {
    try {
      Map<String, dynamic> m = {
        "username": username,
        "password": password,
      };
      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      var res = await http.post(Uri.parse("$SERVER_IP/login"), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (res.contentLength == 0) {
        Map<String, dynamic> m = {
          "error": true,
          "message": "No response from server",
        };

        return m;
      }

      if (res.statusCode == 200) {
        var data =
            decryptAESCryptoJS(res.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        Map<String, dynamic> r = json.decode(data);

        var username = r["username"];
        var addr = r["addr"];
        var jwt = r["jwt"];
        var userID = r["userid"];
        var adminPriv = r["admin"];
        var nickname = r["nickname"];

        storage.write(key: globals.USERNAME, value: username);
        storage.write(key: globals.ADR, value: addr);
        storage.write(key: globals.ID, value: userID.toString());
        storage.write(key: globals.TOKEN, value: jwt);
        storage.write(key: globals.ADMINPRIV, value: adminPriv.toString());
        storage.write(key: globals.NICKNAME, value: nickname.toString());

        String udid = await FlutterUdid.consistentUdid;
        storage.write(key: globals.UDID, value: udid);
        Map<String, dynamic> m = {
          "error": false,
          "message": res.body,
        };
        return m;
      } else {
        var data =
            decryptAESCryptoJS(res.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        var error = '';
        if(data.toString() == 'User does not exists') {
          error = AppLocalizations.of(context)!.user_not_exists;
        }else{
          error = data.toString();
        }
        Map<String, dynamic> m = {
          "error": true,
          "message": error,
        };

        return m;
      }
    } on TimeoutException catch (_) {
      Map<String, dynamic> m = {
        "error": true,
        "message": "No response from server",
      };
      return m;
    } on SocketException catch (_) {
      Map<String, dynamic> m = {
        "error": true,
        "message": "No response from server",
      };
      return m;
    } catch (e) {
      var error = '';
      if(e.toString().trim() == 'User does not exists') {
        error = AppLocalizations.of(context)!.user_not_exists;
      }else{
        error = e.toString();
      }
      Map<String, dynamic> m = {
        "error": true,
        "message": error,
      };
      return m;
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale _myLocale = Localizations.localeOf(context);
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
                Material(
                  type: MaterialType.transparency,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      AppLocalizations.of(context)!.login,
                      style: Theme.of(context).textTheme.headline1,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Align(
                  alignment: Alignment.topCenter,
                  child: Image(
                    image: AssetImage('images/konjlogo.png'),
                    fit: BoxFit.fitWidth,
                    width: 130,
                    alignment: Alignment.topCenter,
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
            child: GestureDetector(
              onTap: () {
                Dialogs.openForgotPasswordBox(context, _checkSendEmail);
              },
              child: Text(
                AppLocalizations.of(context)!.forgot_pass,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    color: Colors.white38,
                    fontSize: 16.0),
              ),
            ),
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Container(
                        color: Theme.of(context).konjHeaderColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 20.0, left: 10.0, right: 10.0),
                              child: TextField(
                                controller: _usernameController,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^[a-zA-Z0-9@._-\s]+')),
                                ],
                                decoration: InputDecoration(
                                  fillColor: Colors.black26,
                                  filled: true,
                                  hintText: AppLocalizations.of(context)!.username + " | " + AppLocalizations.of(context)!.email,
                                  hintStyle:
                                      Theme.of(context).textTheme.subtitle1,
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.white, width: 1.0),
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.white30, width: 0.5),
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  border: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.white30, width: 1),
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                ),
                                style: Theme.of(context).textTheme.bodyText2,
                                onEditingComplete: () {},
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 15.0, left: 10.0, right: 10.0),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  fillColor: Colors.black26,
                                  filled: true,
                                  hintText: AppLocalizations.of(context)!.password,
                                  hintStyle:
                                      Theme.of(context).textTheme.subtitle1,
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.white, width: 1.0),
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.white30, width: 0.5),
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  border: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.white30, width: 1),
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                ),
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                            ),
                            const SizedBox( height: 5.0,),
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(5.0),
                              child: _myLocale.languageCode == "fi" ? StyledText(
                                style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0),
                                textAlign: TextAlign.center,
                                text: AppLocalizations.of(context)!.login_can_use,
                                tags: {
                                  'bold': StyledTextTag(style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white)),
                                },
                              ) : RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: AppLocalizations.of(context)!.login_can_use,
                                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                  children: <TextSpan>[
                                    TextSpan(text: ' wendy.network', style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, fontWeight: FontWeight.bold)),
                                TextSpan(
                                  text: ' ' + AppLocalizations.of(context)!.login.toString().toLowerCase(),
                                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                )],
                                ),
                              ),
                            ),
                            const SizedBox( height: 15.0,),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 0.0, left: 50.0, right: 50.0),
                              child: SizedBox(
                                width: 150,
                                height: 40,
                                child: ClipRRect(
                                  borderRadius:
                                      const BorderRadius.all(Radius.circular(15.0)),
                                  child: Material(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        side: const BorderSide(
                                            color: Colors.transparent)),
                                    color: Colors.white,
                                    child: InkWell(
                                        splashColor: Theme.of(context).konjCardColor,
                                        onTap: () async {
                                          var _username =
                                              _usernameController.text;
                                          var _password =
                                              _passwordController.text;
                                          if(_username.isEmpty || _password.isEmpty) {
                                            Dialogs.openAlertBox(
                                                context,
                                                AppLocalizations.of(context)!.warning,
                                                AppLocalizations.of(context)!.fields_cant_empty);
                                            return;
                                          }
                                          Dialogs.openWaitBox(context);
                                          var jwt = await attemptLogIn(context,
                                              _username, _password);
                                          if (jwt['error'] == false) {
                                            Navigator.of(context).pop();
                                            // storage.write(key: "jwt", value: jwt);
                                            Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const MainMenuScreen()));
                                          } else {
                                            Navigator.of(context).pop();
                                            Dialogs.openAlertBox(
                                                context,
                                                AppLocalizations.of(context)!.error_occur,
                                                jwt['message']);
                                          }
                                        },
                                        child: Padding(
                                            padding: const EdgeInsets.only(top: 5.0),
                                            child: Text(AppLocalizations.of(context)!.log_in,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1!
                                                    .copyWith(
                                                        color: Colors.black)))),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Padding(
                                padding: const EdgeInsets.only(
                                    top: 5.0, bottom: 10.0),
                                child: SizedBox(
                                  width: 150,
                                  child: ClipRRect(
                                      borderRadius:
                                          const BorderRadius.all(Radius.circular(15.0)),
                                      child: Material(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                              side: const BorderSide(
                                                  color: Colors.transparent)),
                                          color: Colors.black26,
                                          child: InkWell(
                                              splashColor: Theme.of(context).konjCardColor,
                                              onTap: () async {
                                                Navigator.push(
                                                    context,
                                                    CupertinoPageRoute<bool>(
                                                        builder: (context) =>
                                                            const RegisterScreen()));
                                              },
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(10.0),
                                                  child: Text(AppLocalizations.of(context)!.sign_up,
                                                      textAlign: TextAlign.center,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyText1!
                                                          .copyWith(
                                                              color: Colors
                                                                  .white70, fontSize: 14.0)))))),
                                )),
                          ],
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
