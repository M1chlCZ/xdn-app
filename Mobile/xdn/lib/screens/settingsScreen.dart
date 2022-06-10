import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/auth_screen.dart';
import 'package:digitalnote/screens/security_screen.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/widgets/backgroundWidget.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;

class SettingsScreen extends StatefulWidget {
  static const String route = "menu/settings";

  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsState();
  }
}

class _SettingsState extends State<SettingsScreen> {
  final StreamController<bool> _verificationNotifier = StreamController<bool>.broadcast();
  PackageInfo? packageInfo;
  bool isAuthenticated = false;
  int confirmation = 1;
  String? firstPass;
  bool _reload = false;
  var twoFactor = false;
  var settingUP = false;
  var run = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _getTwoFactor();
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

  void _saveFile() async {
    var status = await Permission.storage.status;
    if (await Permission.storage.isPermanentlyDenied) {
      if (mounted) await Dialogs.openAlertBoxReturn(context, AppLocalizations.of(context)!.warning, AppLocalizations.of(context)!.storage_perm);
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
      String name = "transactionsXDN${_getNow(DateTime.now())}.csv";

      if (Platform.isIOS) {
        Directory tempDir = await getApplicationDocumentsDirectory();
        String tempPath = tempDir.path;
        filePath = '$tempPath/$name';
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.set_download),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            elevation: 5.0,
          ));
        }
        var path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
        filePath = '$path/$name';
      }

      var bytes = ByteData.view(data!.buffer);
      final buffer = bytes.buffer;

      var f = await File(filePath).writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      if (mounted) Navigator.of(context).pop();
      var result = await OpenFile.open(f.path);
      if (result.type == ResultType.noAppToOpen) {
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_csv_no_app);
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _handlePIN() async {
    var bl = false;
    String? p = await SecureStorage.read(key: globals.PIN);
    if (p == null) {
      bl = true;
    }
    if (mounted) {
      Navigator.of(context).pushNamed(AuthScreen.route, arguments: {"bl": bl, "type": 1}).then((value) {
        if (value != null) {
          bool v = value as bool;
          _authCallback(v);
        }
      });
    }
  }

  void _authCallback(bool? b) {
    if (b == null || b == false) return;
    Navigator.of(context).pushNamed(SecurityScreen.route);
    // Navigator.of(context)
    //     .push(PageRouteBuilder(pageBuilder:
    //     (BuildContext context, _, __) {
    //   return const SecurityScreen();
    // }, transitionsBuilder: (_,
    //     Animation<double> animation,
    //     __,
    //     Widget child) {
    //   return FadeTransition(
    //       opacity: animation,
    //       child: child);
    // }));
  }

  void _initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        arc: false,
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
        )),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Builder(
                builder: (context) => SafeArea(
                      child: SingleChildScrollView(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Header(header: AppLocalizations.of(context)!.settings_screen),
                          Column(
                            children: [
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () async {
                                          _handlePIN();
                                        },
                                        // button pressed
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 15.0),
                                              child: Icon(
                                                FontAwesomeIcons.lock,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: const AutoSizeText(
                                                "Security", //TODO Security trans
                                                style: TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          if (twoFactor) {
                                            Dialogs.open2FABox(context, _unset2FA);
                                          } else {
                                            _get2FACode();
                                          }
                                        },
                                        // button pressed
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 15.0),
                                              child: Icon(
                                                FontAwesomeIcons.google,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                twoFactor ? "Remove 2FA" : "Set 2FA", //TODO set unset 2FA
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () async {
                                          var name = await SecureStorage.read(key: globals.NICKNAME);
                                          if (mounted) Dialogs.openRenameBox(context, name!, _renameboxCallback);
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
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.set_nickname,
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
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
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.set_password,
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
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
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.set_priv_key,
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () async {
                                          _saveFile();
                                        },
                                        // button pressed
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 15.0),
                                              child: Icon(
                                                FontAwesomeIcons.download,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.set_csv,
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          Dialogs.openLanguageDialog(context, (value) => null, (save) => null, 0);
                                        },
                                        // button pressed
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 15.0),
                                              child: Icon(
                                                FontAwesomeIcons.globe,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.change_language,
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          showAboutDialog(
                                              context: context,
                                              applicationName: 'DigitalNote',
                                              applicationIcon: Image.asset(
                                                "images/logo_send.png",
                                                width: 45.0,
                                                height: 45.0,
                                                color: Colors.black87,
                                              ),
                                              applicationVersion: packageInfo!.version,
                                              children: [
                                                Text(
                                                  'Developed by:',
                                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                                Text(
                                                  'M1chlCZ, Nessie',
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
                                                  '©DigitalNote Team 2022',
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
                                                FontAwesomeIcons.circleInfo,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.set_about,
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Theme.of(context).canvasColor.withOpacity(0.8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          Dialogs.openLogoutConfirmationBox(context);
                                        },
                                        // button pressed
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 15.0),
                                              child: Icon(
                                                FontAwesomeIcons.signOut,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.set_log_out,
                                                style: const TextStyle(fontSize: 20, color: Colors.white70),
                                                minFontSize: 8,
                                                maxLines: 1,
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ]),
                      ),
                    ))),
      ),
    ]);
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
      if (mounted) {
        Navigator.of(context).pop();
        Dialogs.openPasswordConfirmBox(context, _passChange);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_pass_error);
      }
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
      if (priv != null) {
        if (mounted) {
          Navigator.of(context).pop();
          Dialogs.openPrivKeyQR(context, priv);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_priv_error);
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_pass_error);
      }
    }
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
      if (kDebugMode) {
        print(e);
      }
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
        var req = await cm.get("/data", request: m);
        if (req['status'] == 'ok') {
          if (mounted) Navigator.of(context).pop();
          setState(() {
            twoFactor = true;
          });
          if(mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, "2FA activated");
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
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
      http.Response response = await cm.get('/data', typeContent: ComInterface.typePlain, request: m);
      if (response.statusCode == 200) {
        setState(() {
          twoFactor = false;
        });
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              "2FA disabled",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            elevation: 5.0,
          ));
        }
      } else {
        if (mounted) {
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
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    settingUP = false;
  }
}
