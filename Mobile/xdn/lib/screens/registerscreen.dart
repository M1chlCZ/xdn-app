import 'dart:async';
import 'dart:io';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/loginscreen.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_udid/flutter_udid.dart';


class RegisterScreen extends StatefulWidget {
  static const String route = "/register";

  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RegisterState();
  }
}

class _RegisterState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _realnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<int> attemptSignUp(String username, String password, String email, String realname) async {
    try {
      String udid = await FlutterUdid.consistentUdid;

      Map<String, dynamic> m = {
        "username": username,
        "password": password,
        "realname": realname,
        "email": email,
        "udid": udid,
      };

      ComInterface ci = ComInterface();
      var response = await ci.post("/register", body: m, type: ComInterface.typePlain, serverType: ComInterface.serverGoAPI, debug: false);

      return response.statusCode;
    } on TimeoutException catch (_) {
      if (kDebugMode) {
        print('Cannot connect to service');
      }
      return Future.error('Cannot connect to service');
    } on SocketException catch (_) {
      if (kDebugMode) {
        print('Cannot connect to service');
      }
      return Future.error('Cannot connect to service');
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return Future.error('Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(hasImage: false, image: ""),
        SafeArea(
            child: Stack(children: [
          Column(
            children: [
              const SizedBox(
                height: 30.0,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    AppLocalizations.of(context)!.registration,
                    style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 24.0),
                  ),
                ),
              ),
            ],
          ),
        ])),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Builder(
            builder: (context) => SingleChildScrollView(
                reverse: true,
                child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + kToolbarHeight)),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 250.0, left: 15, right: 15),
                        child: Container(
                          margin: const EdgeInsets.only(top: 40.0),
                          padding: const EdgeInsets.only(top: 10.0),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0xFF22283A).withOpacity(0.5)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _usernameController,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9_\-\s]+')),
                                  ],
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.username,
                                    hintStyle: Theme.of(context).textTheme.subtitle1,
                                    contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white, width: 1.0), borderRadius: BorderRadius.circular(10.0)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 0.5), borderRadius: BorderRadius.circular(10.0)),
                                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(10.0)),
                                  ),
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _realnameController,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'^[A-zÀ-ÖØ-öø-įĴ-őŔ-žǍ-ǰǴ-ǵǸ-țȞ-ȟȤ-ȳɃɆ-ɏḀ-ẞƀ-ƓƗ-ƚƝ-ơƤ-ƥƫ-ưƲ-ƶẠ-ỿ\s]+')),
                                  ],
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.first_last_name,
                                    hintStyle: Theme.of(context).textTheme.subtitle1,
                                    contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white, width: 1.0), borderRadius: BorderRadius.circular(10.0)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 0.5), borderRadius: BorderRadius.circular(10.0)),
                                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(10.0)),
                                  ),
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.email,
                                    hintStyle: Theme.of(context).textTheme.subtitle1,
                                    contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white, width: 1.0), borderRadius: BorderRadius.circular(10.0)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 0.5), borderRadius: BorderRadius.circular(10.0)),
                                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(10.0)),
                                  ),
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.password,
                                    hintStyle: Theme.of(context).textTheme.subtitle1,
                                    contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white, width: 1.0), borderRadius: BorderRadius.circular(10.0)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 0.5), borderRadius: BorderRadius.circular(10.0)),
                                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(10.0)),
                                  ),
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _passwordConfirmController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.conf_password,
                                    hintStyle: Theme.of(context).textTheme.subtitle1,
                                    contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white, width: 1.0), borderRadius: BorderRadius.circular(10.0)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 0.5), borderRadius: BorderRadius.circular(10.0)),
                                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(10.0)),
                                  ),
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                              const SizedBox(
                                height: 20.0,
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
                                  child: SizedBox(
                                    width: 300,
                                    child: FlatCustomButton(
                                        radius: 15.0,
                                        color: Colors.white70,
                                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                                        onTap: () async {
                                          var realname = _realnameController.text;
                                          var username = _usernameController.text;
                                          var password = _passwordController.text;
                                          var passwordConfirm = _passwordConfirmController.text;
                                          var email = _emailController.text;
                                          bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);

                                          if (username.length < 4) {
                                            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.username_invalid, AppLocalizations.of(context)!.username_invalid_message);
                                          } else if (password.length < 4) {
                                            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.password_invalid, AppLocalizations.of(context)!.password_invalid_message);
                                          } else if (!emailValid) {
                                            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.email_invalid, AppLocalizations.of(context)!.email_invalid_message);
                                          } else if (realname.length < 6) {
                                            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.name_invalid, AppLocalizations.of(context)!.name_invalid_message);
                                          } else if (password != passwordConfirm) {
                                            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.password_mismatch, AppLocalizations.of(context)!.password_mismatch_message);
                                          } else {
                                            var res = await attemptSignUp(username, password, email, realname);
                                            if (res == 201) {
                                              if (mounted) {
                                                await Dialogs.openAlertBox(context, AppLocalizations.of(context)!.succ, "${AppLocalizations.of(context)!.reg_succ_message}!")
                                                    .then((value) => Navigator.of(context).pushNamedAndRemoveUntil(LoginPage.route, (Route<dynamic> route) => false));
                                              }
                                            } else if (res == 409) {
                                              if (mounted) {
                                                Dialogs.openAlertBox(context, AppLocalizations.of(context)!.usr_exists_err, AppLocalizations.of(context)!.usr_exists_err_message);
                                              }
                                            } else {
                                              if (mounted) {
                                                Dialogs.openAlertBox(context, "Error", "An unknown error occurred.");
                                              }
                                            }
                                          }
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.sign_up,
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0, color: Colors.black87),
                                        )),
                                  )),
                              const SizedBox(
                                height: 15.0,
                              )
                            ],
                          ),
                        ),
                      ),
                    ))),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 80.0, left: 20.0),
          child: SizedBox.fromSize(
            size: const Size(40, 40), // button width and height

            child: ClipOval(
              child: Material(
                color: const Color(0xFF22283A).withOpacity(0.5), // button color
                child: InkWell(
                  splashColor: Colors.white.withOpacity(0.8), // splash color
                  onTap: () {
                    Navigator.pop(context);
                  }, // button pressed
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Icon(
                        Icons.arrow_back,
                        color: Colors.white70,
                      ), // icon
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
