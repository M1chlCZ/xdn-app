import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';
import 'package:digitalnote/widgets/backgroundWidget.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info/package_info.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../globals.dart' as globals;
import '../support/CardHeader.dart';
import '../support/ColorScheme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsState();
  }
}

class _SettingsState extends State<SettingsScreen> {
  final StreamController<bool> _verificationNotifier = StreamController<bool>.broadcast();
  final storage = const FlutterSecureStorage();
  PackageInfo? packageInfo;
  bool isAuthenticated = false;
  int confirmation = 1;
  String? firstPass;
  bool _reload = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  void _removePinHandler(String pin) async {
    Navigator.of(context).pop();
    String? s = await storage.read(key: globals.PIN);
    if (pin == s) {
      await storage.delete(key: globals.PIN);
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.succ,AppLocalizations.of(context)!.set_pin_removed );
    } else {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error,AppLocalizations.of(context)!.set_pin_not_match );
    }
  }

  void _saveFile() async {
    var status = await Permission.storage.status;
    if (await Permission.storage.isPermanentlyDenied) {
      await Dialogs.openAlertBoxReturn(context, AppLocalizations.of(context)!.warning, AppLocalizations.of(context)!.storage_perm);
      openAppSettings();
    } else if (status.isDenied) {
      var r = await Permission.storage.request();
      if (r.isGranted) {
        _downloadFile();
      }
    } else {
      _downloadFile();
    }
  }

  String _getNow(DateTime date) => DateFormat("yyyyMMddHHmmss").format(date);

  void _downloadFile() async {
    Dialogs.openWaitBox(context);
    try {
      String filePath;
      Uint8List? data = await NetInterface.downloadCSV(context);
      String name = "transactionsKONJ" + _getNow(DateTime.now()) + ".csv";

      if (Platform.isIOS) {
        Directory tempDir = await getApplicationDocumentsDirectory();
        String tempPath = tempDir.path;
        filePath = tempPath + '/$name';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.set_download),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
        var path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
        filePath = path + '/$name';
      }

      var bytes = ByteData.view(data!.buffer);
      final buffer = bytes.buffer;

      var f = await File(filePath).writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      Navigator.of(context).pop();
      var result = await OpenFile.open(f.path);
      if (result.type == ResultType.noAppToOpen) {
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_csv_no_app);
      }
    } catch (e) {
      Navigator.of(context).pop();
      print(e);
    }
  }

  void _initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        arc: true,
        mainMenu: true,
      ),

      Theme(
        data: Theme.of(context).copyWith(
      textTheme: TextTheme(
        headline5: GoogleFonts.montserrat(
          color: Colors.black54,
          fontSize: 14.0,
          fontWeight: FontWeight.w300,
        ),
        bodyText2: GoogleFonts.montserrat(
          color: Colors.black54,
          fontWeight: FontWeight.w300,
        ),
      )
      ),
        child: Scaffold(

            backgroundColor: Colors.transparent,
            body: Builder(
                builder: (context) => SingleChildScrollView(
                    reverse: true,
                    child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + kToolbarHeight)),
                        child: IntrinsicHeight(
                          child: SafeArea(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              CardHeader(
                                title: AppLocalizations.of(context)!.set_headline.toUpperCase(),
                                backArrow: true,
                              ),
                              Container(
                                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                child: Column(
                                  children: [
                                    Divider(
                                      height: 2.0,
                                      color: Colors.white54.withOpacity(0.5),
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.10),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color
                                          onTap: () async {
                                            var s = await storage.containsKey(key: globals.PIN);
                                            if (s) {
                                              Dialogs.openPinRemoveBox(context, _removePinHandler);
                                              return;
                                            }
                                            _showLockScreen(
                                              context,
                                              text: AppLocalizations.of(context)!.pin_enter,
                                              opaque: false,
                                              cancelButton: Text(
                                                AppLocalizations.of(context)!.cancel,
                                                style: const TextStyle(fontSize: 16, color: Colors.white),
                                                semanticsLabel: AppLocalizations.of(context)!.cancel,
                                              ),
                                            );
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 55.0),
                                                child: Icon(
                                                  Icons.lock,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              FutureBuilder(
                                                  future: storage.read(key: globals.PIN),
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return SizedBox(
                                                        width: MediaQuery.of(context).size.width - 200.0,
                                                        child: AutoSizeText(
                                                          AppLocalizations.of(context)!.set_pin,
                                                          style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                          minFontSize: 8,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      );
                                                    } else {
                                                      return SizedBox(
                                                        width: MediaQuery.of(context).size.width - 200.0,
                                                        child: AutoSizeText(
                                                          AppLocalizations.of(context)!.set_remove_pin,
                                                          style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                          minFontSize: 8,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      );
                                                    }
                                                  }),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 20.0,
                                      color: Colors.transparent,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.26),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color
                                          onTap: () async {
                                            var name = await storage.read(key: globals.NICKNAME);
                                            Dialogs.openRenameBox(context, name!, _renameboxCallback);
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 15.0),
                                                child: Icon(
                                                  FontAwesomeIcons.userEdit,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width - 200.0,
                                                child: AutoSizeText(
                                                  AppLocalizations.of(context)!.set_nickname,
                                                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                  minFontSize: 8,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 20.0,
                                      color: Colors.transparent,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.31),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color
                                          onTap: () async {
                                            Dialogs.openPasswordChangeBox(context, _passCheck);
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 15.0),
                                                child: Icon(
                                                  FontAwesomeIcons.key,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width - 200.0,
                                                child: AutoSizeText(
                                                  AppLocalizations.of(context)!.set_password,
                                                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                  minFontSize: 8,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 20.0,
                                      color: Colors.transparent,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.31),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color
                                          onTap: () async {
                                            Dialogs.openPasswordChangeBox(context, _passCheckPrivKey);
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 15.0),
                                                child: Icon(
                                                  FontAwesomeIcons.signature,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width - 200.0,
                                                child: AutoSizeText(
                                                  AppLocalizations.of(context)!.set_priv_key,
                                                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                  minFontSize: 8,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 20.0,
                                      color: Colors.transparent,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.31),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color
                                          onTap: () {
                                            _saveFile();
                                            // Dialogs.openLogoutConfirmationBox(context, storage);
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 15.0),
                                                child: Icon(
                                                  Icons.download,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width - 200.0,
                                                child: AutoSizeText(
                                                  AppLocalizations.of(context)!.set_csv,
                                                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                  minFontSize: 8,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 20.0,
                                      color: Colors.transparent,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.26),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color
                                          onTap: () {
                                            Dialogs.openLanguageDialog(context, (value) => null, (save) => null, 0);
                                            // Dialogs.openLogoutConfirmationBox(context, storage);
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 15.0),
                                                child: Icon(
                                                  Icons.language,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width - 200.0,
                                                child: AutoSizeText(
                                                  AppLocalizations.of(context)!.change_language,
                                                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                  minFontSize: 8,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 20.0,
                                      color: Colors.transparent,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.20),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color

                                          onTap: () {
                                            showAboutDialog(
                                                context: context,
                                                applicationName: 'Konjungate',
                                                applicationIcon: Image.asset(
                                                  "images/qrlogo.png",
                                                  width: 45.0,
                                                  height: 45.0,
                                                ),
                                                applicationVersion: packageInfo!.version,
                                                children: [
                                                  Text(
                                                    'Developed by:',
                                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.black, fontSize: 12.0),
                                                  ),
                                                  Text(
                                                    'M1chlCZ, Nessie, GilMonteverde',
                                                    style: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.black, fontSize: 12.0),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    'App version:',
                                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.black, fontSize: 12.0),
                                                  ),
                                                  Text(
                                                    packageInfo!.version,
                                                    style: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.black, fontSize: 12.0),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    '©Konjungate Team 2021',
                                                    style: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.black, fontSize: 12.0),
                                                  ),
                                                ]);
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 15.0),
                                                child: Icon(
                                                  Icons.info,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)!.set_about,
                                                style: const TextStyle(color: Colors.white70, fontSize: 20.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 20.0,
                                      color: Colors.transparent,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.10),
                                      height: 60,
                                      width: MediaQuery.of(context).size.width - 20.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        // button color
                                        child: InkWell(
                                          splashColor: Colors.white,
                                          // splash color
                                          onTap: () {
                                            Dialogs.openLogoutConfirmationBox(context, storage);
                                          },
                                          // button pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 15.0),
                                                child: Icon(
                                                  Icons.logout,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 15.0,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)!.set_log_out,
                                                style: const TextStyle(color: Colors.white70, fontSize: 20.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ]),
                          ),
                        ))))),
      ),
      Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            left: -100.0,
            top: MediaQuery.of(context).size.height / 2 - 128,
            child: const AvatarPicker(
              size: 200.0,
              padding: 0,
              userID: null,
            ),
          ),
        ],
      ),
    ]);
  }

  _showLockScreen(
    BuildContext context, {
    required String text,
    required bool opaque,
    CircleUIConfig? circleUIConfig,
    KeyboardUIConfig? keyboardUIConfig,
    required Widget cancelButton,
    List<String>? digits,
  }) {
    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: opaque,
          pageBuilder: (context, animation, secondaryAnimation) => PasscodeScreen(
            title: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 28),
            ),
            circleUIConfig: circleUIConfig,
            keyboardUIConfig: keyboardUIConfig,
            passwordEnteredCallback: _onPasscodeEntered,
            cancelButton: cancelButton,
            deleteButton: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              semanticsLabel: AppLocalizations.of(context)!.delete,
            ),
            shouldTriggerVerification: _verificationNotifier.stream,
            backgroundColor: Theme.of(context).konjCardColor,
            cancelCallback: _onPasscodeCancelled,
            digits: digits,
            passwordDigits: 6,
            // bottomWidget: _buildPasscodeRestoreButton(),
          ),
        ));
  }

  _onPasscodeEntered(String enteredPasscode) {
    setState(() {
      if (confirmation == 1) {
        Navigator.pop(context);
        firstPass = enteredPasscode;
        confirmation++;
        _showLockScreen(
          context,
          text: AppLocalizations.of(context)!.set_pin_confirm,
          opaque: false,
          cancelButton: Text(
            AppLocalizations.of(context)!.cancel,
            style: const TextStyle(fontSize: 16, color: Colors.white),
            semanticsLabel: AppLocalizations.of(context)!.cancel,
          ),
        );
      } else {
        bool isValid = firstPass == enteredPasscode;
        storage.write(key: globals.PIN, value: enteredPasscode);
        _verificationNotifier.add(isValid);
        if (isValid) {
          setState(() {
            isAuthenticated = isValid;
          });
          _restartApp();
        }
      }
    });
  }

  void _restartApp() async {
    Phoenix.rebirth(context);
  }

  _onPasscodeCancelled() {
    Navigator.maybePop(context);
  }

  @override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }

  _renameboxCallback(String nickname) {
    NetInterface.renameUser(context, nickname);
    _reload = true;
  }

  _passCheck(String password) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    var succ = await NetInterface.checkPassword(password);
    if (succ) {
      Navigator.of(context).pop();
      Dialogs.openPasswordConfirmBox(context, _passChange);
    } else {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_pass_error);
    }
  }

  _passChange(String password) {
    NetInterface.changePassword(context, password);
  }

  _passCheckPrivKey(String password) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    var succ = await NetInterface.checkPassword(password);
    if (succ) {
      String? priv = await NetInterface.getPrivKey();
      if(priv != null) {
        Navigator.of(context).pop();
        Dialogs.openPrivKeyQR(context, priv);
      }else{
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_priv_error);
      }
    } else {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_pass_error);
    }
  }
}
