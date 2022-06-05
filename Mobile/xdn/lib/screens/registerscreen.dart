import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:http/http.dart' as http;
import 'package:digitalnote/globals.dart' as globals;
import 'package:digitalnote/screens/loginscreen.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Encrypt.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:styled_text/styled_text.dart';

import '../support/ColorScheme.dart';

const SERVER_IP = globals.SERVER_URL;

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
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();


  @override
  void initState() {
    super.initState();
  }

  Future<int> attemptSignUp(
      String username, String password, String email, String realname) async {
    try {
      String udid = await FlutterUdid.consistentUdid;

      Map<String, dynamic> m = {
        "username": username,
        "password": password,
        "realname": realname,
        "email": email,
        "udid": udid,
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response =
          await http.post(Uri.parse(globals.SERVER_URL + '/signup'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      return response.statusCode;
    } on TimeoutException catch (_) {
      print('Cannot connect to service');
      return Future.error('Cannot connect to service');
    } on SocketException catch (_) {
      print('Cannot connect to service');
      return Future.error('Cannot connect to service');
    } catch (e) {
      print(e.toString());
      return Future.error('Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale _myLocale = Localizations.localeOf(context);
    return Stack(
      children: [
        const BackgroundWidget(hasImage: false, image: ""),
        SafeArea(
            child: Stack(children: [
          Column(
            children: [
              const Align(
                alignment: Alignment.topCenter,
                child: Image(
                  image: AssetImage('images/konjlogo.png'),
                  fit: BoxFit.fitWidth,
                  width: 140,
                  alignment: Alignment.topCenter,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    AppLocalizations.of(context)!.registration,
                    style: Theme.of(context)
                        .textTheme
                        .headline5!
                        .copyWith(fontSize: 32.0),
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
                    constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            (MediaQuery.of(context).padding.top +
                                kToolbarHeight)),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 250.0, left: 15, right: 15),
                        child: Container(
                          margin: const EdgeInsets.only(top: 0.0),
                          padding: const EdgeInsets.only(top: 10.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Theme.of(context).konjHeaderColor),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _usernameController,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^[a-zA-Z0-9_-\s]+')),
                                  ],
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.username,
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
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _realnameController,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(
                                        r'^[A-zÀ-ÖØ-öø-įĴ-őŔ-žǍ-ǰǴ-ǵǸ-țȞ-ȟȤ-ȳɃɆ-ɏḀ-ẞƀ-ƓƗ-ƚƝ-ơƤ-ƥƫ-ưƲ-ƶẠ-ỿ\s]+')),
                                  ],
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.first_last_name,
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
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.email,
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
                              Padding(
                                padding: const EdgeInsets.all(10.0),
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
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  controller: _passwordConfirmController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    fillColor: Colors.black26,
                                    filled: true,
                                    hintText: AppLocalizations.of(context)!.conf_password,
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
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.all(10.0),
                                child:_myLocale.countryCode == "FI" ? StyledText(
                                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0),
                                  textAlign: TextAlign.center,
                                  text: AppLocalizations.of(context)!.wendy_first + ' ' +AppLocalizations.of(context)!.description+ ' \n \n ' + AppLocalizations.of(context)!.wendy_second + ' '+AppLocalizations.of(context)!.wendy_third+' '+AppLocalizations.of(context)!.wendy_fourth+'. \n \n '+ AppLocalizations.of(context)!.wendy_fifth +'.',
                                  tags: {
                                    'bold': StyledTextTag(style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white)),
                                  },
                                ) :
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: AppLocalizations.of(context)!.wendy_first + ' ' +AppLocalizations.of(context)!.description+ ' \n \n ',
                                    style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: AppLocalizations.of(context)!.wendy_second,
                                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                      ),
                                      TextSpan(text: ' wendy.network \n', style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, fontWeight: FontWeight.bold)),
                                      TextSpan(
                                          text: ' '+AppLocalizations.of(context)!.wendy_third+' \n '+AppLocalizations.of(context)!.wendy_fourth+'. \n \n '+ AppLocalizations.of(context)!.wendy_fifth +'.',
                                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, bottom: 10.0),
                                  child: SizedBox(
                                    width: 300,
                                    child: RaisedButton(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                            side: const BorderSide(
                                                color: Colors.transparent)),
                                        color: Colors.white70,
                                        textColor: Colors.black,
                                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                                        onPressed: () async {
                                          var realname = _realnameController.text;
                                          var username = _usernameController.text;
                                          var password = _passwordController.text;
                                          var passwordConfirm =
                                              _passwordConfirmController.text;
                                          var email = _emailController.text;
                                          bool emailValid = RegExp(
                                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                              .hasMatch(email);

                                          if (username.length < 4) {
                                            Dialogs.openAlertBox(
                                                context,
                                                AppLocalizations.of(context)!.username_invalid,
                                                AppLocalizations.of(context)!.username_invalid_message);
                                          } else if (password.length < 4) {
                                            Dialogs.openAlertBox(
                                                context,
                                                AppLocalizations.of(context)!.password_invalid,
                                                AppLocalizations.of(context)!.password_invalid_message);
                                          } else if (!emailValid) {
                                            Dialogs.openAlertBox(
                                                context,
                                                AppLocalizations.of(context)!.email_invalid,
                                                AppLocalizations.of(context)!.email_invalid_message);
                                          } else if (realname.length < 6) {
                                            Dialogs.openAlertBox(
                                                context,
                                                AppLocalizations.of(context)!.name_invalid,
                                                AppLocalizations.of(context)!.name_invalid_message);
                                          } else if (password !=
                                              passwordConfirm) {
                                            Dialogs.openAlertBox(
                                                context,
                                                AppLocalizations.of(context)!.password_mismatch,
                                                AppLocalizations.of(context)!.password_mismatch_message);
                                          } else {
                                            var res = await attemptSignUp(
                                                username,
                                                password,
                                                email,
                                                realname);
                                            if (res == 201) {
                                              await Dialogs.openAlertBox(
                                                      context,
                                                  AppLocalizations.of(context)!.succ,
                                                  AppLocalizations.of(context)!.reg_succ_message + "!")
                                                  .then((value) => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const LoginPage())));
                                            } else if (res == 409) {
                                              Dialogs.openAlertBox(
                                                  context,
                                                  AppLocalizations.of(context)!.usr_exists_err,
                                                  AppLocalizations.of(context)!.usr_exists_err_message);
                                            } else {
                                              Dialogs.openAlertBox(
                                                  context,
                                                  "Error",
                                                  "An unknown error occurred.");
                                            }
                                          }
                                        },
                                        child: Text(AppLocalizations.of(context)!.sign_up, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0, color: Colors.black87), )),
                                  )),
                              const SizedBox(
                                height: 5.0,
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
                color: Colors.white, // button color
                child: InkWell(
                  splashColor: Colors.white.withOpacity(0.8), // splash color
                  onTap: () {
                    Navigator.pop(context);
                  }, // button pressed
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Icon(Icons.arrow_back), // icon
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
