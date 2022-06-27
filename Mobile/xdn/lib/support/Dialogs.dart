import 'dart:io';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/RoundButton.dart';
import 'package:digitalnote/support/auto_size_text_field.dart';
import 'package:digitalnote/support/barcode_scanner.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import '../globals.dart' as globals;
import '../screens/loginscreen.dart';
import 'AppDatabase.dart';
import 'ColorScheme.dart';
import 'Contact.dart';
import 'DialogBody.dart';
import 'NetInterface.dart';
import 'RadioAlertWidget.dart';
import 'TranSaction.dart';
import 'Utils.dart';

class Dialogs {
  static void openContactSendBox(context, String name, String addr, Function(String amount, String name, String addr) func) async {
    TextEditingController textController = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
              buttonLabel: AppLocalizations.of(context)!.send,
              onTap: () {
                func(textController.text, name, addr);
              },
              header: "${AppLocalizations.of(context)!.send} $name",
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: Colors.black12,
                  ),
                  padding: const EdgeInsets.all(5.0),
                  width: 500,
                  child: TextField(
                    autofocus: true,
                    controller: textController,
                    keyboardType: Platform.isIOS ? const TextInputType.numberWithOptions(signed: true) : TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .headline6!
                        .copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white.withOpacity(0.8)),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline6!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.amount,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ));
        });
  }

  static void openMessageTipBox(context, String name, String addr, Function(String amount, String name, String addr) func) async {
    TextEditingController textController = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            buttonLabel: AppLocalizations.of(context)!.send,
            oneButton: false,
            onTap: () {
              func(textController.text, name, addr);
            },
            header: "${AppLocalizations.of(context)!.tip} $name",
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: TextField(
                  autofocus: true,
                  controller: textController,
                  keyboardType: Platform.isIOS ? const TextInputType.numberWithOptions(signed: true) : TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                  ],
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white.withOpacity(0.8)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(5.0),
                    hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                    hintText: AppLocalizations.of(context)!.amount,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          );
        });
  }

  static void openRenameBox(context, String name, Function(String nickname) func) async {
    TextEditingController textController = TextEditingController();
    textController.text = name;
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
              header: "${AppLocalizations.of(context)!.rename} $name",
              buttonLabel: 'OK',
              onTap: () {
                func(textController.text);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: Colors.black12,
                  ),
                  padding: const EdgeInsets.all(5.0),
                  width: 500,
                  child: TextField(
                    autofocus: true,
                    controller: textController,
                    keyboardType: TextInputType.text,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9]+')),
                    ],
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 32),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.new_name,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ));
        });
  }

  static void openPinRemoveBox(context, Function(String nickname) func) async {
    TextEditingController textController = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
              header: AppLocalizations.of(context)!.dl_remove_pin,
              buttonLabel: 'OK',
              onTap: () {
                func(textController.text);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: Colors.black12,
                  ),
                  padding: const EdgeInsets.all(5.0),
                  width: 500,
                  child: TextField(
                    obscureText: true,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    textAlign: TextAlign.center,
                    controller: textController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+')),
                    ],
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 48),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.dl_enter_pin,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ));
        });
  }

  static void openSendContactConfirmBox(
      context, String name, String addr, String amount, Function(String amount, String name, String addr) func) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: AppLocalizations.of(context)!.send,
            onTap: () {
              func(amount, name, addr);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  AppLocalizations.of(context)!.dl_send_confirm,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static void openContactDeteleBox(context, int id, Function(int id) func) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: AppLocalizations.of(context)!.yes,
            onTap: () {
              func(id);
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: SizedBox(
                width: 380,
                child: AutoSizeText(
                  AppLocalizations.of(context)!.dl_delete_contact,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static void openSendConfirmBox(context, Function() func) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: AppLocalizations.of(context)!.send,
            onTap: () {
              func();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  AppLocalizations.of(context)!.dl_send_confirm,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static void openAmbassadorConfirmBox(context, bool val, Function(bool val) func) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: AppLocalizations.of(context)!.yes,
            onTap: () {
              func(val);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  val == true ? "Do you really want to change status to Ambassador?" : "Do you really want to cancel Ambassador status?",
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static void openAmbassadorBanBox(context, VoidCallback func) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: 'Yes',
            onTap: () {
              func();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  "Do you really want to ban this user?",
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static void openLogoutConfirmationBox(context) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: AppLocalizations.of(context)!.yes,
            onTap: () async {
              Navigator.of(context).pop();
              SecureStorage.deleteAllStorage();
              AppDatabase().deleteTableAddr();
              AppDatabase().deleteTableMessages();
              AppDatabase().deleteTableMgroup();
              AppDatabase().deleteTableTran();
              String fileName = "avatar";
              String dir = (await getApplicationDocumentsDirectory()).path;
              String savePath = '$dir/$fileName';
              File f = File(savePath);
              try {
                await f.delete();
              } catch (e) {
                print(e);
              }
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  AppLocalizations.of(context)!.dl_log_out,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static Future<void> open2FABox(context, Function(String? s) func) async {
    final TextEditingController txt = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          var copyIconVisible = true;
          return StatefulBuilder(builder: (BuildContext context, StateSetter sState) {
            txt.addListener(() {
              if (txt.text.isEmpty) {
                copyIconVisible = true;
                sState(() {});
              } else {
                copyIconVisible = false;
                sState(() {});
              }

              if (txt.text.length == 6) {
                func(txt.text);
                return;
              }
            });
            return DialogBody(
              header: "Google 2FA",
              buttonLabel: 'OK',
              oneButton: false,
              noButtons: true,
              onTap: () {
                func(txt.text);
                // Navigator.of(context).pop(true);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15.0, right: 15.0),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                        child: Container(
                          color: Colors.black38,
                          padding: const EdgeInsets.all(15.0),
                          child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            autofocus: true,
                            controller: txt,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            decoration: InputDecoration(
                              isDense: false,
                              contentPadding: const EdgeInsets.only(bottom: 0.0),
                              hintStyle: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.white54, fontSize: 18.0),
                              hintText: "Google 2FA",
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                            ),
                            style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 24.0, color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: copyIconVisible,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 25.0, right: 8),
                          child: GestureDetector(
                            onTap: () async {
                              ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                              // print(data!.text!);
                              sState(() {
                                if (data!.text != null) {
                                  txt.text = data.text!;
                                }
                                txt.selection = TextSelection.collapsed(offset: txt.text.length);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.all(Radius.circular(5.0))),
                              child: const Padding(
                                padding: EdgeInsets.all(3.0),
                                child: Icon(
                                  Icons.paste,
                                  color: Color(0xFFFFD301),
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }

  static Future<void> open2FASetBox(context, String code, Function(String? s) func) async {
    final TextEditingController textController = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          var copyIconVisible = true;
          return StatefulBuilder(builder: (BuildContext context, StateSetter sState) {
            textController.addListener(() {
              if (textController.text.isEmpty) {
                copyIconVisible = true;
              } else {
                copyIconVisible = false;
              }
              sState(() {});
              if (textController.text.length == 6) {
                func(textController.text);
                return;
              }
            });
            return DialogBody(
              header: "Google 2FA",
              buttonLabel: 'OK',
              oneButton: false,
              noButtons: true,
              onTap: () {
                // func(textController.text);
                // Navigator.of(context).pop(true);
              },
              child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15.0, right: 15.0),
                      child: SizedBox(
                          width: double.infinity,
                          child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                              child: Container(
                                color: Colors.black38,
                                padding: const EdgeInsets.all(15.0),
                                child: Text(
                                  "Copy the code provided to the Google Authetificator and paste 2FA code from it",
                                  style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 18.0, color: Colors.white70),
                                ),
                              )))),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15.0, right: 15.0),
                      child: SizedBox(
                          width: double.infinity,
                          child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                              child: Container(
                                color: Colors.black38,
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: AutoSizeText(
                                        code,
                                        maxLines: 1,
                                        minFontSize: 8.0,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 14.0, color: Colors.white70),
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 5.0, right: 2),
                                        child: GestureDetector(
                                          onTap: () async {
                                            Clipboard.setData(ClipboardData(text: code));
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(3.0),
                                            child: Icon(
                                              Icons.copy,
                                              color: Color(0xFFFFD301),
                                              size: 25,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )))),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15.0, right: 15.0),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                            child: Container(
                              color: Colors.black38,
                              padding: const EdgeInsets.all(15.0),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                autofocus: true,
                                controller: textController,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  isDense: false,
                                  contentPadding: const EdgeInsets.only(bottom: 0.0),
                                  hintStyle: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.white54, fontSize: 18.0),
                                  hintText: "Google 2FA",
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.transparent),
                                  ),
                                ),
                                style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 24.0, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: copyIconVisible,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 25.0, right: 8),
                              child: GestureDetector(
                                onTap: () async {
                                  ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                                  // print(data!.text!);
                                  sState(() {
                                    if (data!.text != null) {
                                      textController.text = data.text!;
                                    }
                                    textController.selection = TextSelection.collapsed(offset: textController.text.length);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                  child: const Padding(
                                    padding: EdgeInsets.all(3.0),
                                    child: Icon(
                                      Icons.paste,
                                      color: Color(0xFFFFD301),
                                      size: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  static void openBetaWarningBox(context) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: 'OK',
            oneButton: true,
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  "This is the XDN mobile wallet beta version. There will be no guarantees or claims if your funds are lost. Use of the app is at your own risk and responsibility and send only small amounts of funds.",
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 8,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static Future<void> openAlertBox(context, String header, String message) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: 'OK',
            oneButton: true,
            onTap: () {
              Navigator.of(context).pop(true);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                width: 500,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AutoSizeText(
                    message,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 8,
                    minFontSize: 8.0,
                    style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0, color: Colors.white70, letterSpacing: 1.0),
                  ),
                ),
              ),
            ),
          );
        });
  }

  static void openInsufficientBox(context) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: 'OK',
            oneButton: true,
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  "${AppLocalizations.of(context)!.dl_not_enough_coins}!",
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 8,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static void openWaitBox(context) async {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.dl_wait,
            noButtons: true,
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 5.0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 300,
                child: const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }

  static void openForgotPasswordBox(context, Function(String nickname) func) async {
    TextEditingController textController = TextEditingController();
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.dl_credentials,
            buttonLabel: 'OK',
            onTap: () {
              func(textController.text);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0, bottom: 10.0),
              child: SizedBox(
                width: 350,
                child: AutoSizeTextField(
                  autofocus: true,
                  controller: textController,
                  keyboardType: TextInputType.text,
                  style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 32),
                  decoration: InputDecoration(
                    hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                    hintText: AppLocalizations.of(context)!.email,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          );
        });
  }

  static void openContactEditBox(context, Contact c, VoidCallback func) async {
    TextEditingController textController = TextEditingController();
    textController.text = c.name!;
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
              header: AppLocalizations.of(context)!.dl_edit_name,
              buttonLabel: AppLocalizations.of(context)!.save,
              onTap: () async {
                await AppDatabase().editContact(textController.text, c.id.toString());
                func();
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: Colors.black12,
                  ),
                  padding: const EdgeInsets.all(5.0),
                  width: 500,
                  child: TextField(
                    autofocus: true,
                    controller: textController,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9_-\s]+')),
                    ],
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 32),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.name,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ));
        });
  }

  static void openContactAddBox(context, Function(String name, String addr) func, Function func2, String addr) async {
    TextEditingController _textControllerName = TextEditingController();
    TextEditingController _textControllerAddr = TextEditingController();
    _textControllerAddr.text = addr;
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.dl_new_contact,
            buttonLabel: AppLocalizations.of(context)!.save,
            onTap: () {
              func(_textControllerName.text, _textControllerAddr.text);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0, left: 10.0, right: 10.0, bottom: 5.0),
              child: Column(children: [
                SizedBox(
                  width: 350,
                  child: AutoSizeTextField(
                    autofocus: true,
                    controller: _textControllerName,
                    keyboardType: TextInputType.text,
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 32),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.name,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                const Divider(
                  color: Colors.grey,
                  height: 4.0,
                ),
                SizedBox(
                  width: 350,
                  child: AutoSizeTextField(
                    autofocus: false,
                    controller: _textControllerAddr,
                    keyboardType: TextInputType.text,
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 32),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.address,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                const Divider(
                  color: Colors.grey,
                  height: 4.0,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints.tightFor(width: 300, height: 50),
                  child: TextButton.icon(
                    icon: const Icon(
                      Icons.qr_code_sharp,
                      color: Colors.white54,
                    ),
                    label: Text(
                      'QR',
                      style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0, color: Colors.white54),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith((states) => qrColors(states)),
                    ),
                    onPressed: () {
                      func2();
                    },
                  ),
                ),
              ]),
            ),
          );
        });
  }

  static Future<void> openMessageContactAddBox(context, String addr) async {
    TextEditingController _textControllerName = TextEditingController();
    var res = await AppDatabase().getContactByAddr(addr);
    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.dl_user_exist),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        elevation: 5.0,
      ));
      return;
    }
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.dl_save_contact,
            buttonLabel: AppLocalizations.of(context)!.save,
            onTap: () async {
              try {
                NetInterface.saveContact(_textControllerName.text.toString(), addr, context);
              } catch (e) {
                debugPrint(e.toString());
              }
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0, left: 10.0, right: 10.0, bottom: 5.0),
              child: Column(children: [
                SizedBox(
                  width: 350,
                  child: AutoSizeTextField(
                    autofocus: true,
                    controller: _textControllerName,
                    keyboardType: TextInputType.text,
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 32),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.name,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                const Divider(
                  color: Colors.grey,
                  height: 4.0,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 350,
                    child: AutoSizeText(
                      addr,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      minFontSize: 24,
                      style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5.0,
                ),
              ]),
            ),
          );
        });
  }

  static void openPasswordChangeBox(context, Function(String password) func) async {
    TextEditingController textController = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
              header: AppLocalizations.of(context)!.dl_enter_current_pass,
              buttonLabel: "OK",
              onTap: () {
                func(textController.text);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: Colors.black12,
                  ),
                  padding: const EdgeInsets.all(5.0),
                  width: 500,
                  child: TextField(
                    obscureText: true,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    textAlign: TextAlign.left,
                    controller: textController,
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 48),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 32.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.dl_enter_pass,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ));
        });
  }

  static void openTransactionBox(context, TranSaction tx) async {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          var link = "https://xdn-explorer.com/tx/${tx.txid!}";
          return DialogBody(
            header: AppLocalizations.of(context)!.dl_tx_detail,
            buttonLabel: AppLocalizations.of(context)!.dl_explorer,
            buttonCancelLabel: AppLocalizations.of(context)!.close,
            oneButton: false,
            onTap: () async {
              if (await canLaunch(link)) {
                await launch(link);
              } else {
                print('Could not launch $link');
              }
            },
            child: Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0, bottom: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              AppLocalizations.of(context)!.txid,
                              style:
                                  Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: tx.txid));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!.dl_tx_copy),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.fixed,
                              elevation: 5.0,
                            ));
                          },
                          child: SizedBox(
                            width: 350,
                            height: 20,
                            child: AutoSizeText(
                              tx.txid!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style:
                                  Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    const Divider(
                      color: Colors.grey,
                      height: 4.0,
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              AppLocalizations.of(context)!.amount,
                              style:
                                  Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SizedBox(
                          width: 350,
                          height: 20,
                          child: AutoSizeText(
                            "${tx.amount!} XDN",
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style:
                                Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    const Divider(
                      color: Colors.grey,
                      height: 4.0,
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              AppLocalizations.of(context)!.date,
                              style:
                                  Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SizedBox(
                          width: 350,
                          height: 20,
                          child: AutoSizeText(
                            Utils.convertDate(tx.datetime),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style:
                                Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    const Divider(
                      color: Colors.grey,
                      height: 4.0,
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              AppLocalizations.of(context)!.confirmations.capitalize(),
                              style:
                                  Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SizedBox(
                          width: 350,
                          height: 20,
                          child: AutoSizeText(
                            tx.confirmation.toString(),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style:
                                Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 18.0, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
          );
        });
  }

  static void openPasswordConfirmBox(context, Function(String password) func) async {
    TextEditingController textController = TextEditingController();
    TextEditingController textController2 = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
              header: AppLocalizations.of(context)!.dl_new_enter_pass,
              buttonLabel: "OK",
              onTap: () {
                var p = textController.text;
                var c = textController2.text;
                if (p == c) {
                  func(textController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocalizations.of(context)!.dl_pass_mismatch),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.fixed,
                    elevation: 5.0,
                  ));
                }
              },
              child: Column(children: [
                SizedBox(
                  height: 60.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0, bottom: 0.0),
                    child: TextField(
                      obscureText: true,
                      autofocus: true,
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: TextAlign.left,
                      controller: textController,
                      style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 22),
                      decoration: InputDecoration(
                        hintStyle:
                            Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 22.0, color: Colors.white54),
                        hintText: AppLocalizations.of(context)!.dl_new_enter_pass,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const Divider(
                  color: Colors.grey,
                  height: 4.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0, bottom: 5.0),
                  child: TextField(
                    obscureText: true,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    textAlign: TextAlign.left,
                    controller: textController2,
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 22),
                    decoration: InputDecoration(
                      hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, fontSize: 22.0, color: Colors.white54),
                      hintText: AppLocalizations.of(context)!.dl_conf_new_pass,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ]));
        });
  }

  static void openUserQR(context) async {
    var qr = await SecureStorage.read(key: globals.ADR);
    showDialog(
        context: context,
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
            child: Dialog(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(side: BorderSide(color: Color(0xFF9F9FA4)), borderRadius: BorderRadius.all(Radius.circular(20.0))),
              child: Wrap(children: [
                Container(
                  width: 400.0,
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0, bottom: 2.0),
                          child: SizedBox(
                            width: 380,
                            child: AutoSizeText(
                              AppLocalizations.of(context)!.dl_konj_addr,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 8.0,
                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      Center(
                          child: Text(
                        '(${AppLocalizations.of(context)!.dl_share})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0, color: Colors.black54),
                      )),
                      const SizedBox(
                        height: 5.0,
                      ),
                      const Divider(
                        color: Colors.grey,
                        height: 4.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: qr));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!.dl_qr_copy),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.fixed,
                              elevation: 5.0,
                            ));
                            Navigator.pop(context);
                          },
                          onLongPress: () {
                            Vibration.vibrate(duration: 200);
                            Share.share(qr!);
                            Navigator.pop(context);
                          },
                          child: QrImage(
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            data: qr.toString(),
                            foregroundColor: Colors.black87,
                            version: QrVersions.auto,
                            // size: 250,
                            gapless: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ]),
            ),
          );
        });
  }

  static void openPrivKeyQR(context, String privKey) async {
    var qr = privKey;
    showDialog(
        context: context,
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.withOpacity(0.5)), borderRadius: const BorderRadius.all(Radius.circular(20.0))),
              child: Wrap(children: [
                Container(
                  width: 400.0,
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0, bottom: 2.0),
                          child: SizedBox(
                            width: 380,
                            child: AutoSizeText(
                              AppLocalizations.of(context)!.dl_konj_priv,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 8.0,
                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      Center(
                          child: Text(
                        '(${AppLocalizations.of(context)!.dl_share})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0, color: Colors.black87),
                      )),
                      const SizedBox(
                        height: 5.0,
                      ),
                      const Divider(
                        color: Colors.grey,
                        height: 4.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: qr));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!.dl_priv_copy),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.fixed,
                              elevation: 5.0,
                            ));
                            Navigator.pop(context);
                          },
                          onLongPress: () {
                            Vibration.vibrate(duration: 200);
                            Share.share(qr);
                            Navigator.pop(context);
                          },
                          child: QrImage(
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            data: qr.toString(),
                            foregroundColor: Colors.black,
                            version: QrVersions.auto,
                            // size: 250,
                            gapless: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ]),
            ),
          );
        });
  }

  static void openSelectContactDialog(context, String addr, String name, Function? func, Function(String a, String b)? func2, Function? func3) async {
    showDialog(
        context: context,
        builder: (context) {
          return DialogBody(
              header: AppLocalizations.of(context)!.dl_select_action,
              noButtons: true,
              onTap: () {
                Navigator.of(context).pop(1);
              },
              child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 10, left: 8.0, right: 8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      color: Colors.black12,
                    ),
                    padding: const EdgeInsets.all(5.0),
                    width: 500,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          height: 10.0,
                        ),
                        SizedBox(
                          height: 50.0,
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: Colors.blue,
                              highlightColor: Colors.transparent,
                              onTap: () {
                                func!();
                              },
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!.dl_send_message,
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 20.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Divider(
                            color: Colors.white24,
                            height: 4.0,
                          ),
                        ),
                        SizedBox(
                          height: 50.0,
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: Colors.blue,
                              highlightColor: Colors.transparent,
                              onTap: () {
                                func2!(addr, name);
                              },
                              child: Center(
                                child: Text(
                                  '${AppLocalizations.of(context)!.dl_send_konj} $name',
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 20.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Divider(
                            color: Colors.white24,
                            height: 4.0,
                          ),
                        ),
                        SizedBox(
                          height: 50.0,
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: Colors.blue,
                              highlightColor: Colors.transparent,
                              onTap: () {
                                func3!();
                              },
                              child: Center(
                                child: Text(
                                  '${AppLocalizations.of(context)!.share} $name ${AppLocalizations.of(context)!.contact.toLowerCase()}',
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 20.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15.0,
                        )
                      ],
                    ),
                  )));
        });
  }

  static void openSelectContactListDialog(context, String name, Function(Contact c)? func) async {
    showDialog(
        context: context,
        builder: (context) {
          Locale _myLocale = Localizations.localeOf(context);
          return DialogBody(
              header: _myLocale.countryCode == "FI"
                  ? AppLocalizations.of(context)!.to
                  : '${AppLocalizations.of(context)!.share} ${AppLocalizations.of(context)!.contact.toLowerCase()} ${AppLocalizations.of(context)!.to}:',
              buttonLabel: 'OK',
              noButtons: true,
              onTap: () {
                Navigator.of(context).pop(1);
              },
              child: Padding(
                  padding: const EdgeInsets.only(top: 3.0, bottom: 10, left: 8.0, right: 8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      color: Colors.black12,
                    ),
                    padding: const EdgeInsets.all(0.0),
                    width: 500,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          height: 10.0,
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: SingleChildScrollView(
                            child: FutureBuilder(
                                future: AppDatabase().getShareContactList(name),
                                builder: (context, snapshot) {
                                  var list = snapshot.data as List<Contact>?;
                                  if (snapshot.hasData) {
                                    return ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: list!.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          var cont = list[index];
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                onTap: () {
                                                  func!(cont);
                                                },
                                                leading: SizedBox(
                                                  width: 50.0,
                                                    child: AvatarPicker(
                                                      userID: cont.getAddr()!,
                                                      color: Colors.transparent,
                                                    )),
                                                tileColor: Colors.transparent,
                                                title: SizedBox(
                                                  width: 150,
                                                  child: AutoSizeText(
                                                    cont.getName()!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.headline5!.copyWith(
                                                          color: Colors.white70,
                                                        ),
                                                  ),
                                                ),
                                                subtitle: SizedBox(
                                                  width: 150,
                                                  child: AutoSizeText(
                                                    cont.getAddr()!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.headline5!.copyWith(
                                                          color: Colors.white.withOpacity(0.5),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                                child: SizedBox(
                                                  height: 1,
                                                  child: Container(color: Colors.white.withOpacity(0.2)),
                                                ),
                                              )
                                            ],
                                          );
                                        });
                                  } else {
                                    return Container();
                                  }
                                }),
                          ),
                        ),
                        const SizedBox(
                          height: 15.0,
                        )
                      ],
                    ),
                  )));
        });
  }

  static Future<dynamic> openAlertBoxReturn(context, String header, String message) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: AppLocalizations.of(context)!.alert,
            buttonLabel: 'OK',
            oneButton: true,
            onTap: () {
              Navigator.of(context).pop(1);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  message,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 8,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 22.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static void openLanguageDialog(context, Function(int value) func, Function(bool save) func2, int val) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
              oneButton: true,
              header: AppLocalizations.of(context)!.change_language,
              buttonLabel: 'OK',
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      color: Colors.black12,
                    ),
                    padding: const EdgeInsets.all(5.0),
                    width: 500,
                    child: RadioAlertWidget(func: func),
                  )));
        });
  }

  static void displayDialog(context, title, text) => showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(title), content: Text(text)),
      );

  static Color qrColors(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.white;
    }
    return Colors.transparent;
  }

  static Future<void> openGenericAlertBox(context,
      {String? header, required String message, Function()? onTap, Function()? onCancel, bool? oneButton}) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return DialogBody(
            header: header ?? AppLocalizations.of(context)!.alert,
            buttonLabel: 'OK',
            oneButton: oneButton ?? true,
            onTap: onTap,
            onCancel: onCancel,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0, left: 8.0, right: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.black12,
                ),
                padding: const EdgeInsets.all(5.0),
                width: 500,
                child: AutoSizeText(
                  message,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 8,
                  minFontSize: 8.0,
                  style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 16.0, color: Colors.white70),
                ),
              ),
            ),
          );
        });
  }

  static Future<void> openUserAddBox(BuildContext context) async {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          TextEditingController controller = TextEditingController();
          TextEditingController controllerAddr = TextEditingController();
          return StatefulBuilder(builder: (context, setState) {
            void _openQRScanner() async {
              FocusScope.of(context).unfocus();
              Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
                return BarcodeScanner(
                  scanResult: (String s) {
                    controllerAddr.text = s;
                  },
                );
              }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
                return FadeTransition(opacity: animation, child: child);
              }));
            }

            void _saveUsers(String name, String addr) async {
              Dialogs.openWaitBox(context);
              await NetInterface.saveContact(name, addr, context);
              await NetInterface.getAddrBook();
              await AppDatabase().getContacts();
              Future.delayed(const Duration(milliseconds: 100), () {
                Navigator.of(context).pop();
              });
              Future.delayed(const Duration(milliseconds: 100), () {
                Navigator.of(context).pop();
              });

              setState(() {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalizations.of(context)!.contact_added),
                  backgroundColor: const Color(0xFF63C9F3),
                  behavior: SnackBarBehavior.fixed,
                  elevation: 5.0,
                ));
              });
            }

            return DialogBody(
              dialogWidth: MediaQuery.of(context).size.width * 0.95,
              noButtons: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.only(top: 10.0, left: 15.0, right: 15.0, bottom: 10.0),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    color: Color(0xFF22283A),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10.0,
                      ),
                      TextField(
                        controller: controller,
                        style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.all(8.0),
                          filled: true,
                          hoverColor: Colors.white24,
                          focusColor: Colors.white24,
                          fillColor: const Color(0xFF303850),
                          labelText: "",
                          labelStyle: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white54, fontSize: 18.0),
                          hintText: AppLocalizations.of(context)!.name,
                          hintStyle: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white54, fontSize: 22.0),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.white70,
                          ),
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white10, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black12, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                        ),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Flexible(
                          child: FractionallySizedBox(
                            widthFactor: 0.95,
                            child: SizedBox(
                              height: 45,
                              child: TextField(
                                controller: controllerAddr,
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                                decoration: InputDecoration(
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  contentPadding: const EdgeInsets.only(left: 8.0),
                                  filled: true,
                                  hoverColor: Colors.white24,
                                  focusColor: Colors.white24,
                                  fillColor: const Color(0xFF303850),
                                  labelText: "",
                                  labelStyle: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white54, fontSize: 10.0),
                                  hintText: AppLocalizations.of(context)!.address,
                                  hintStyle: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white54, fontSize: 22.0),
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white10, width: 2.0),
                                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black12, width: 2.0),
                                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 0.0, top: 1.0),
                          child: RoundButton(
                              height: 40,
                              width: 40,
                              color: const Color(0xFF22283A),
                              onTap: () {
                                _openQRScanner();
                              },
                              splashColor: Colors.black45,
                              icon: const Icon(
                                Icons.qr_code,
                                size: 35,
                                color: Colors.white70,
                              )),
                        ),
                      ]),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextButton.icon(
                                    icon: const Icon(
                                      Icons.person_add,
                                      color: Colors.white70,
                                    ),
                                    label: Text(
                                      AppLocalizations.of(context)!.contact_add,
                                      style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                                    ),
                                    style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.resolveWith((states) => sendColors(states)),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)))),
                                    onPressed: () {
                                      _saveUsers(controller.text, controllerAddr.text);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                    ],
                  ),
                ),
              ]),
            );
          });
        });
  }

  static Color sendColors(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.green.withOpacity(0.8);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
