import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/auth_screen.dart';
import 'package:digitalnote/screens/blockchain_info.dart';
import 'package:digitalnote/screens/loginscreen.dart';
import 'package:digitalnote/screens/security_screen.dart';
import 'package:digitalnote/screens/socials_screen.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/daemon_status.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/backgroundWidget.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../globals.dart' as globals;
import '../support/AppDatabase.dart';

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
  bool switchValue = false;
  var twoFactor = false;
  var settingUP = false;
  var run = false;
  var valid = false;
  DaemonStatus? getInfo;
  String? tempPass;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _getTwoFactor();
    _getInfoGet();
    _getSSLPin();
    Future.delayed(Duration.zero, () async {
      var b = await _initPlatform();
      setState(() {
        valid = b;
      });
    });
  }

  Future<bool> _initPlatform() async {
    var di = await getDeviceInfo();
    if (di == false) {
      return false;
    }
    if (Platform.isAndroid) {
      try {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;
        var dots = tempPath.replaceAll(".", "");
        var numDots = tempPath.length - dots.length;
        var bundleOK = numDots < 3 ? true : false;
        var st = tempPath.split("/data/user");
        String packageName = packageInfo.packageName;
        if (packageName == "com.m1chl.xdn" && st.length == 2 && bundleOK && !tempPath.contains("virtual")) {
          return true;
        } else {
          return false;
        }
      } on PlatformException {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<bool> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      if (iosInfo.isPhysicalDevice) {
        return true;
      } else {
        return false;
      }
    } else if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      bool andr = androidInfo.isPhysicalDevice;
      if (andr) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  _getTwoFactor() async {
    try {
      ComInterface ci = ComInterface();
      Map<String, dynamic> m = await ci.get("/twofactor/check", request: {}, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
      Future.delayed(Duration.zero, () {
        setState(() {
          twoFactor = m['twoFactor'];
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  _getInfoGet() async {
    try {
      ComInterface cm = ComInterface();
      Map<String, dynamic> req = await cm.get("/status", serverType: ComInterface.serverGoAPI, debug: true);
      DaemonStatus dm = DaemonStatus.fromJson(req['data']);
      setState(() {
        getInfo = dm;
      });
    } catch (e) {
      debugPrint(e.toString());
      return null;
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
      String name = "transactionsXDN${_getNow(DateTime.now())}.xlsx";

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
      var result = await OpenFilex.open(f.path);
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
          headlineSmall: GoogleFonts.montserrat(
            color: Colors.black54,
            fontSize: 14.0,
            fontWeight: FontWeight.w300,
          ),
          bodyMedium: GoogleFonts.montserrat(
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
                              Opacity(
                                opacity: valid ? 1.0 : 0.5,
                                child: SizedBox(
                                  height: 60,
                                  width: MediaQuery.of(context).size.width - 20.0,
                                  child: Card(
                                    color: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5.0),
                                      child: Material(
                                        color: Colors.black12,
                                        child: InkWell(
                                          splashColor: Colors.white54,
                                          // splash color
                                          onTap: () {
                                            if (valid) {
                                              Navigator.of(context).pushNamed(SocialScreen.route);
                                            } else {
                                              Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "This section is not allowed while running app  in vm or emulator");
                                            }
                                          },
                                          // labelLarge pressed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(left: 10.0),
                                                child: Image.asset(
                                                  "images/socials_general.png",
                                                  height: 32.0,
                                                  width: 32.0,
                                                  color: const Color(0xFFBDBEC2),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10.0,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width - 100.0,
                                                child: AutoSizeText(
                                                  AppLocalizations.of(context)!.socials_popup.toLowerCase().capitalize(),
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
                              ),
                              const Divider(
                                height: 5.0,
                                color: Colors.transparent,
                              ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () async {
                                          _handlePIN();
                                        },
                                        // labelLarge pressed
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
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.security,
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
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
                                        // labelLarge pressed
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
                                                twoFactor ? AppLocalizations.of(context)!.remove_2fa : AppLocalizations.of(context)!.set_2fa, //TODO set unset 2FA
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () async {
                                          var name = await SecureStorage.read(key: globals.NICKNAME);
                                          if (mounted) Dialogs.openRenameBox(context, name!, _renameboxCallback);
                                        },
                                        // labelLarge pressed
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          Dialogs.openPasswordChangeBox(context, _passCheck);
                                        },
                                        // labelLarge pressed
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          Dialogs.openPasswordChangeBox(context, _passCheckPrivKey);
                                        },
                                        // labelLarge pressed
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          Navigator.of(context).pushNamed(BlockInfoScreen.route);
                                          // Dialogs.openPasswordChangeBox(context, _passCheckPrivKey);
                                        },
                                        // labelLarge pressed
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 15.0),
                                              child: Icon(
                                                FontAwesomeIcons.info,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.blockchain_info,
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
                              // SizedBox(
                              //   height: 60,
                              //   width: MediaQuery.of(context).size.width - 20.0,
                              //   child: Card(
                              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              //     color: Colors.transparent,
                              //     child: ClipRRect(
                              //       borderRadius: BorderRadius.circular(5.0),
                              //       child: Material(
                              //         color: Colors.black12,
                              //         child: InkWell(
                              //           splashColor: Colors.white54,
                              //           // splash color
                              //           onTap: () {
                              //             // Navigator.of(context).pushNamed(BlockInfoScreen.route);
                              //             // Dialogs.openPasswordChangeBox(context, _passCheckPrivKey);
                              //           },
                              //           // labelLarge pressed
                              //           child: Row(
                              //             mainAxisAlignment: MainAxisAlignment.start,
                              //             crossAxisAlignment: CrossAxisAlignment.center,
                              //             children: [
                              //               const Padding(
                              //                 padding: EdgeInsets.only(left: 15.0),
                              //                 child: Icon(
                              //                   FontAwesomeIcons.userSecret,
                              //                   color: Colors.white70,
                              //                 ),
                              //               ),
                              //               const SizedBox(
                              //                 width: 15.0,
                              //               ),
                              //               const Expanded(
                              //                 child: AutoSizeText(
                              //                   "SSL Pinning",
                              //                   style: TextStyle(fontSize: 20, color: Colors.white70),
                              //                   minFontSize: 8,
                              //                   maxLines: 1,
                              //                   textAlign: TextAlign.start,
                              //                   overflow: TextOverflow.ellipsis,
                              //                 ),
                              //               ),
                              //               SizedBox(
                              //                 width: 80,
                              //                 child: Switch(
                              //                     value: switchValue,
                              //                     activeColor: const Color(0xFF37467C),
                              //                     inactiveThumbColor: Colors.red.withOpacity(0.8),
                              //                     inactiveTrackColor: Colors.transparent,
                              //
                              //                     onChanged: (b) {
                              //                       setState(() {
                              //                         switchValue = b;
                              //                         sslPin(b);
                              //                       });
                              //                     }),
                              //               ),
                              //             ],
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              // const Divider(
                              //   height: 5.0,
                              //   color: Colors.transparent,
                              // ),
                              SizedBox(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 20.0,
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () async {
                                          _saveFile();
                                        },
                                        // labelLarge pressed
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          Dialogs.openLanguageDialog(context, (value) => null, (save) => null, 0);
                                        },
                                        // labelLarge pressed
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
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
                                                  'Daemon version:',
                                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                                Text(
                                                  getInfo!.version ?? 'unknown',
                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  'Developed by:',
                                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                                Text(
                                                  'M1chlCZ, Nessie',
                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  'App version:',
                                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                                Text(
                                                  packageInfo!.version,
                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  '©DigitalNote Team 2022',
                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black, fontSize: 12.0),
                                                ),
                                              ]);
                                        },
                                        // labelLarge pressed
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
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Material(
                                      color: Colors.black12,
                                      child: InkWell(
                                        splashColor: Colors.white54,
                                        // splash color
                                        onTap: () {
                                          Dialogs.openLogoutConfirmationBox(context);
                                        },
                                        // labelLarge pressed
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
                                          Dialogs.openDeleteAccountFirstBox(context, _removeCheck);
                                        },
                                        // labelLarge pressed
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 15.0),
                                              child: Icon(
                                                FontAwesomeIcons.remove,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width - 100.0,
                                              child: AutoSizeText(
                                                AppLocalizations.of(context)!.delete_acc,
                                                style: const TextStyle(fontSize: 20, color: Colors.red),
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

  // void _restartApp() async {
  //   Phoenix.rebirth(context);
  // }
  //
  // _onPasscodeCancelled() {
  //   Navigator.maybePop(context);
  // }

  @override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }

  _renameboxCallback(String nickname) {
    NetInterface.renameUser(context, nickname);
  }

  _passCheck(String password, {String? pin}) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    dynamic succ = await NetInterface.checkPassword(password, pin: pin);
    if (succ is bool) {
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
      if (tempPass != null && pin != null) {
        tempPass == null;
      }
    } else if (succ is String) {
      if (mounted) Navigator.of(context).pop();
      tempPass = password;
      if (mounted) Dialogs.open2FABox(context, _auth2FAPass);
    }
  }

  _removeCheck(String password, {String? pin}) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    dynamic succ = await NetInterface.checkPassword(password, pin: pin);
    if (succ is bool) {
      if (succ) {
        if (mounted) {
          Navigator.of(context).pop();
          Dialogs.openDeleteAccountSecondBox(context, _removeAccount);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.set_pass_error);
        }
      }
      if (tempPass != null && pin != null) {
        tempPass == null;
      }
    } else if (succ is String) {
      if (mounted) Navigator.of(context).pop();
      tempPass = password;
      if (mounted) Dialogs.open2FABox(context, _remove2FAPass);
    }
  }

  var runDelete = false;

  _removeAccount() async {
    if (runDelete) return;
    runDelete = true;
    Navigator.of(context).pop();
    var succ = await NetInterface.deleteAccount();
    if (succ != null && succ['status'] == 'ok') {
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
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } else {
      runDelete = false;
      if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "We were unable to delete your account, please contact support");
    }
  }

  _auth2FAPass(String? s) async {
    _passCheck(tempPass!, pin: s);
  }

  _remove2FAPass(String? s) async {
    _removeCheck(tempPass!, pin: s);
  }

  _passChange(String password) {
    NetInterface.changePassword(context, password);
  }

  _passCheckPrivKey(String password, {String? pin}) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    dynamic succ = await NetInterface.checkPassword(password, pin: pin);
    if (succ is bool) {
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
      if (tempPass != null && pin != null) {
        tempPass == null;
      }
    } else if (succ is String) {
      if (mounted) Navigator.of(context).pop();
      tempPass = password;
      if (mounted) Dialogs.open2FABox(context, _auth2FA);
    }
  }

  _auth2FA(String? s) async {
    _passCheckPrivKey(tempPass!, pin: s);
  }

  _get2FACode() async {
    try {
      ComInterface interface = ComInterface();
      Map<String, dynamic> m = await interface.post("/twofactor", body: {}, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);

      _set2FA(m['code']);
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
      run = true;
      try {
        ComInterface interface = ComInterface();
        http.Response res = await interface.post("/twofactor/activate", body: {"code": s}, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
        if (res.statusCode == 200) {
          if (mounted) Navigator.of(context).pop();
          setState(() {
            twoFactor = true;
          });
          if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, "2FA activated");
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
      ComInterface interface = ComInterface();
      http.Response res = await interface.post("/twofactor/remove", body: {"token": s}, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);
      if (res.statusCode == 200) {
        setState(() {
          twoFactor = false;
        });
        if (mounted) {
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

  void sslPin(bool b) async {
    String? sslEnable = await SecureStorage.read(key: "SSL");
    if (sslEnable == null) {
      await SecureStorage.write(key: "SSL", value: 'true');
    }
    bool ssl = sslEnable == "true";
    if (b == ssl) {
      return;
    } else {
      if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, "App needs to be restarted for changes to be applied");
      await SecureStorage.write(key: "SSL", value: b.toString());
    }
  }

  void _getSSLPin() async {
    String? sslEnable = await SecureStorage.read(key: "SSL");
    if (sslEnable == null) {
      await SecureStorage.write(key: "SSL", value: 'true');
    }
    if (sslEnable == "true") {
      setState(() {
        switchValue = true;
      });
    } else {
      setState(() {
        switchValue = false;
      });
    }
  }
}
