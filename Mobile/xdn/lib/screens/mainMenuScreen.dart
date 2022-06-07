// import 'dart:io';
//
// import 'package:digitalnote/net_interface/interface.dart';
// import 'package:digitalnote/support/daemon_status.dart';
// import 'package:digitalnote/support/secure_storage.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_app_badger/flutter_app_badger.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
// import 'package:flutter_phoenix/flutter_phoenix.dart';
// import 'package:flutter_udid/flutter_udid.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:digitalnote/support/AppDatabase.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:vibration/vibration.dart';
//
// import '../globals.dart' as globals;
// import '../screens/addrScreen.dart';
// import '../screens/settingsScreen.dart';
// import '../screens/stakingScreen.dart';
// import '../screens/walletscreen.dart';
// import '../support/Dialogs.dart';
// import '../support/LifecycleWatcherState.dart';
// import '../support/NetInterface.dart';
// import '../widgets/AvatarPicker.dart';
// import '../widgets/BackgroundWidget.dart';
// import '../widgets/RadialMenu.dart';
// import 'messagescreen.dart';
//
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
// class MainMenuScreen extends StatefulWidget {
//   final String? locale;
//
//   const MainMenuScreen({Key? key, this.locale}) : super(key: key);
//
//   @override
//   MainMenuScreenState createState() => MainMenuScreenState();
// }
//
// class MainMenuScreenState extends LifecycleWatcherState<MainMenuScreen> {
//   final GlobalKey<MessageScreenState> _messageScreenKey = GlobalKey<MessageScreenState>();
//   final GlobalKey<DetailScreenState> _walletScreenKey = GlobalKey<DetailScreenState>();
//   final GlobalKey<StakingScreenState> _stakingScreenKey = GlobalKey<StakingScreenState>();
//
//   FirebaseMessaging? _messaging;
//
//   final bool _adminPrivileges = false;
//   final bool _ambassadorPrivileges = false;
//   bool _pinEnabled = false;
//   bool _paused = false;
//   int _messageCount = 0;
//   bool run = false;
//
//   ComInterface cm = ComInterface();
//
//   void _callback(String name) {
//     if (name == AppLocalizations.of(context)!.menu_wallet) {
//       // Navigator.of(context).push(CupertinoPageRoute(
//       //     builder: (context) => WalletScreen(
//       //           key: _walletScreenKey,
//       //         )));
//     } else if (name == AppLocalizations.of(context)!.st_headline) {
//       Navigator.of(context).push(CupertinoPageRoute(
//           builder: (context) => StakingScreen(
//                 key: _stakingScreenKey,
//               )));
//     } else if (name == AppLocalizations.of(context)!.contacts) {
//       Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const AddressScreen()));
//     } else if (name == AppLocalizations.of(context)!.messages) {
//       Navigator.of(context).push(CupertinoPageRoute(
//           builder: (context) => MessageScreen(
//                 key: _messageScreenKey,
//               )));
//     } else {
//       Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const SettingsScreen())).then((value) => _getUserInfo(reload: value));
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _getUserInfo();
//     _registerNotification();
//     _initializeLocalNotifications();
//     _getPin();
//     _getAddrBook();
//     _getMessages();
//     initializeDateFormatting();
//     _getLocale();
//
//     // if (Foundation.kReleaseMode) {
//     // Future.delayed(const Duration(milliseconds: 100), () {
//     //   if(widget.locale != null)
//     //   Dialogs.openAlertBox(context, "Info", widget.locale!);
//     // });
//     // }
//   }
//
//   @override
//   void setState(fn) {
//     if (mounted) {
//       super.setState(fn);
//     }
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   _get2FACode() async {
//       try {
//         var id = await SecureStorage.read(key: globals.ID);
//         Map<String, dynamic> m = {
//           "request": "twofactor",
//           "id": id
//         };
//         var req = await cm.get("/data", request: m);
//         _set2FA(req['secret']);
//       } catch (e) {
//         Dialogs.openAlertBox(context, "Error", "2FA already turned on");
//         print(e);
//       }
//   }
//
//   _set2FA(String code) async {
//     Dialogs.open2FASetBox(context, code, _confirm2FA);
//   }
//
//   _confirm2FA(String? s) async {
//     if(!run) {
//       run = true;
//       try {
//         var id = await SecureStorage.read(key: globals.ID);
//         Map<String, dynamic> m = {
//           "request": "twofactorValidate",
//           "id": id,
//           "param1": s!
//         };
//         var req = await cm.get("/data", request: m, debug: true);
//         if (req['status'] == 'ok') {
//           if(mounted)Navigator.of(context).pop();
//           Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, "2FA activated");
//         }
//       } catch (e) {
//         print(e);
//       }
//     }
//     run = false;
//   }
//
//   Future<DaemonStatus> _getDaemonStatus() async {
//     Map<String, dynamic> m = {
//       "request": "getDaemonStatus",
//     };
//     var req = await cm.get("/data", request: m);
//     DaemonStatus dm = DaemonStatus.fromJson(req);
//     return dm;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         const BackgroundWidget(
//           mainMenu: true,
//         ),
//         Scaffold(
//             backgroundColor: Colors.transparent,
//             body: LayoutBuilder(
//               builder: (context, constraints) {
//                 var parentHeight = constraints.maxHeight;
//                 var parentWidth = constraints.maxWidth;
//                 return SafeArea(
//                   child: Stack(
//                     children: [
//                       Align(
//                         alignment: Alignment.topCenter,
//                         child: Stack(
//                           alignment: AlignmentDirectional.topCenter,
//                           children: [
//                             AvatarPicker(
//                               size: parentWidth * 0.35,
//                               padding: 5,
//                               userID: null,
//                             ),
//                             Padding(
//                               padding: EdgeInsets.only(top: parentHeight * 0.135),
//                               child: GestureDetector(
//                                 onTap: () {
//                                   _callback("Settings");
//                                 },
//                                 child: Image.asset(
//                                   'images/settingsicon.png',
//                                   color: Colors.white,
//                                   width: parentWidth * 0.15,
//                                   height: parentWidth * 0.15,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.bottomCenter,
//                         child: FutureBuilder<DaemonStatus>(
//                             initialData: DaemonStatus(block: false, blockStake: false, stakingActive: false),
//                             future: _getDaemonStatus(),
//                             builder: (ctx, snapshot) {
//                               return Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Container(
//                                     decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(10.0),
//                                         color: Colors.white10
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 2.0, bottom: 2.0),
//                                       child: Row(
//                                         children: [
//                                           Text("Daemon status", style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0),),
//                                           const SizedBox(width: 5.0,),
//                                           Icon(
//                                             Icons.circle,
//                                             size: 10.0,
//                                             color: snapshot.data!.block! ? Colors.green : Colors.red,
//                                           ),
//
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10.0,),
//                                   Container(
//                                     decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(10.0),
//                                         color: Colors.white10
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 2.0, bottom: 2.0),
//                                       child: Row(
//                                         children: [
//                                           Text("Staking daemon status", style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0),),
//                                           const SizedBox(width: 5.0,),
//                                           Icon(
//                                             Icons.circle,
//                                             size: 10.0,
//                                             color: snapshot.data!.blockStake! ? Colors.green : Colors.red,
//                                           ),
//
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10.0,),
//                                   Container(
//                                     decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(10.0),
//                                         color: Colors.white10
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 2.0, bottom: 2.0),
//                                       child: Row(
//                                         children: [
//                                           Text("Staking active", style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0),),
//                                           const SizedBox(width: 5.0,),
//                                           Icon(
//                                             Icons.circle,
//                                             size: 10.0,
//                                             color: snapshot.data!.stakingActive! ? Colors.green : Colors.red,
//                                           ),
//
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             }),
//                       ),
//                       Align(
//                         alignment: Alignment.bottomLeft,
//                         child: GestureDetector(
//                           onTap: () {
//                             _launchURL("https://digitalnote.net");
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.all(15.5),
//                             child: SizedBox(width: 50, child: Image.asset('images/konjicon.png')),
//                           ),
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.bottomCenter,
//                         child: GestureDetector(
//                           onTap: () {
//                             Dialogs.openUserQR(context);
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.only(bottom: 16.0),
//                             child: Container(
//                               padding: const EdgeInsets.all(4.0),
//                               decoration: BoxDecoration(
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.white.withAlpha(50),
//                                       blurRadius: 6.0,
//                                       spreadRadius: 0.0,
//                                       offset: const Offset(
//                                         0.0,
//                                         3.0,
//                                       ),
//                                     ),
//                                   ],
//                                   border: Border.all(
//                                     width: 2.0,
//                                     color: Colors.white,
//                                   ),
//                                   borderRadius: const BorderRadius.all(Radius.circular(10))),
//                               child: SizedBox(
//                                 width: 40,
//                                 height: 40,
//                                 child: Image.asset(
//                                   'images/QR.png',
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.bottomRight,
//                         child: GestureDetector(
//                           onTap: () {
//                             _get2FACode();
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: SizedBox(width: 50, child: Image.asset('images/wendyicon.png')),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             )),
//         Padding(
//           padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.105, right: MediaQuery.of(context).size.height * 0.003),
//           child: RadialMenu(
//             callback: _callback,
//             admPriv: _adminPrivileges,
//             ambPriv: _ambassadorPrivileges,
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _getAddrBook() async {
//     await NetInterface.getAddrBook();
//   }
//
//   void _getMessages() async {
//     await NetInterface.saveMessageGroup();
//     int? i = await AppDatabase().getUnread();
//     i ??= 0;
//     setState(() {
//       _messageCount = i!;
//     });
//   }
//
//   void _getLocale() async {
//     var timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
//     await SecureStorage.write(key: globals.LOCALE, value: timeZoneName);
//
//     // context.findAncestorWidgetOfExactType<MaterialApp>()?.supportedLocales.forEach((element) {
//     //   print(element.toString());
//     // });
//   }
//
//   void _getUserInfo({bool? reload = true}) async {
//     if (reload != null) {
//       var map = await NetInterface.getAdminNickname();
//       _setUsernameID(map!);
//     }
//   }
//
//   void _setUsernameID(Map map) async {
//     await SecureStorage.write(key: globals.NICKNAME, value: map['nick']);
//     await SecureStorage.write(key: globals.ADMINPRIV, value: map['admin'].toString());
//     await SecureStorage.write(key: globals.LEVEL, value: map['level'].toString());
//     var udid = await FlutterUdid.consistentUdid;
//     SecureStorage.write(key: globals.UDID, value: udid);
//   }
//
//   void _initializeLocalNotifications() async {
//     if (Platform.isAndroid) {
//       AndroidNotificationChannel channel = const AndroidNotificationChannel(
//         'konj1', // id
//         'Send/Receive notifications', // title
//         description: 'This channel is used for transaction notifications.',
//         // description
//         importance: Importance.max,
//         enableVibration: true,
//         enableLights: true,
//         ledColor: Colors.white,
//       );
//
//       await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannel(channel);
//
//       AndroidNotificationChannel channel2 = const AndroidNotificationChannel(
//         'konj2', // id
//         'Message notifications', // title
//         description: 'This channel is used for message notifications.',
//         // description
//         importance: Importance.max,
//         enableVibration: true,
//         enableLights: true,
//         ledColor: Colors.white,
//       );
//
//       await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannel(channel2);
//     }
//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_notification');
//     final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
//     final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
//     flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: _onSelectNotification);
//   }
//
//   void _registerNotification() async {
//     _messaging = FirebaseMessaging.instance;
//
//     _messaging!.getToken().then((value) {
//       NetInterface.registerFirebaseToken(value!);
//       print(value);
//     });
//
//     NotificationSettings settings = await _messaging!.requestPermission(
//       alert: true,
//       badge: true,
//       provisional: false,
//       sound: true,
//     );
//
//     _messaging!.onTokenRefresh.listen((token) {
//       NetInterface.registerFirebaseToken(token);
//     });
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         print(message.data.toString());
//         print(message.notification!.title.toString());
//         // _setBadge();
//         if (message.data.containsKey("transaction")) {
//           Vibration.vibrate(duration: 50);
//           print("refresh balance");
//           if (_walletScreenKey.currentWidget != null) {
//             _walletScreenKey.currentState!.notif();
//           }
//
//           if (_stakingScreenKey.currentWidget != null) {
//             _stakingScreenKey.currentState!.not();
//           }
//         }
//
//         if (message.data.containsKey("incomingMessage")) {
//           Vibration.vibrate(duration: 50);
//           print("new message");
//           _getMessages();
//           if (_messageScreenKey.currentWidget != null) {
//             _messageScreenKey.currentState!.notReceived();
//           }
//         }
//
//         if (message.data.containsKey("outMessage")) {
//           print("sent message");
//           if (_messageScreenKey.currentWidget != null) {
//             _messageScreenKey.currentState!.notReceived();
//           }
//         }
//       });
//     }
//   }
//
//   Future _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
//     // _refreshBalance();
//     // _setBadge();
//     // _imagesave = false;
//   }
//
//   Future _onSelectNotification(String? payload) async {
//     print(payload);
//     // _refreshBalance();
//   }
//
//   Future _getPinFuture() async {
//     var s = SecureStorage.read(key: globals.PIN);
//     return s;
//   }
//
//   void _getPin() async {
//     final String? pin = await _getPinFuture();
//     if (pin != null) _pinEnabled = true;
//   }
//
//   void _restartApp() async {
//     Phoenix.rebirth(context);
//   }
//
//   // void _checkNot() async {
//   //   var res = await storage.read(key: globals.APP_NOT);
//   //   if (res == "yes") {
//   //     await storage.write(key: globals.APP_NOT, value: "no");
//   //     if (_messageScreenKey.currentWidget != null) {
//   //       _messageScreenKey.currentState.notReceived();
//   //     }else {
//   //       _messageScreenKey = GlobalKey<MessageScreenState>();
//   //       Navigator.of(context).popUntil((route) => route.isFirst);
//   //       Navigator.push(
//   //         context,
//   //         CupertinoPageRoute(
//   //             builder: (context) =>
//   //                 MessageScreen(
//   //                   key: _messageScreenKey,
//   //                 )),
//   //       ).then((value) => _getMessages());
//   //     }
//   //   }
//   // }
//
//   void _launchURL(String addr) async {
//     try {
//       if (await canLaunch(addr)) {
//         await launch(addr);
//       } else {
//         throw 'Could not launch $addr';
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   @override
//   void onDetached() {}
//
//   @override
//   void onInactive() {
//     _getMessages();
//   }
//
//   @override
//   void onPaused() {
//     _paused = true;
//   }
//
//   @override
//   void onResumed() {
//     FlutterAppBadger.removeBadge();
//     flutterLocalNotificationsPlugin.cancelAll();
//     // _checkNot();
//     _getPin();
//     _getMessages();
//     if (_pinEnabled == true && _paused) {
//       _paused = false;
//       _restartApp();
//     }
//   }
// }
