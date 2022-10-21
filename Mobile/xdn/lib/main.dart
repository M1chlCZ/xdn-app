import 'dart:convert';
import 'dart:io';

import 'package:digitalnote/screens/addrScreen.dart';
import 'package:digitalnote/screens/auth_screen.dart';
import 'package:digitalnote/screens/blockchain_info.dart';
import 'package:digitalnote/screens/main_menu.dart';
import 'package:digitalnote/screens/message_screen.dart';
import 'package:digitalnote/screens/registerscreen.dart';
import 'package:digitalnote/screens/security_screen.dart';
import 'package:digitalnote/screens/settingsScreen.dart';
import 'package:digitalnote/screens/stakingScreen.dart';
import 'package:digitalnote/screens/token_screen.dart';
import 'package:digitalnote/screens/voting_screen.dart';
import 'package:digitalnote/screens/walletscreen.dart';
import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/locator.dart';
import 'package:digitalnote/support/notification_helper.dart';
import 'package:digitalnote/support/notification_service.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';

import 'firebase_options.dart';
import 'globals.dart' as globals;
import 'screens/loginscreen.dart';
import 'support/MaterialColorGenerator.dart';
import 'widgets/BackgroundWidget.dart';

bool pinUsed = false;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  bool b = await FlutterAppBadger.isAppBadgeSupported();
  if (b) {
    FlutterAppBadger.updateBadgeCount(1);
  }
  SecureStorage.write(key: globals.APP_NOT, value: "yes");
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  // final context = SecurityContext.defaultContext;
  // // modify context as needed
  // var cert = await rootBundle.loadString("assets/cert.pem");
  // context.setTrustedCertificates(cert);
  // final httpClient = HttpClient(context: context);
  // final client = IOClient(httpClient);
  //
  // await client.get(Uri.parse('https://somewhere.io'));

  // try {
  //   SecurityContext(withTrustedRoots: false);
  //   ByteData data = await rootBundle.load("assets/cert.pem");
  //   SecurityContext context = SecurityContext.defaultContext;
  //   context.setTrustedCertificatesBytes(data.buffer.asUint8List());
  //   final httpClient = HttpClient(context: context);
  //   final client = IOClient(httpClient);
  //   await client.get(Uri.parse('https://dex.digitalnote.org/api/api/v1/user/balance'));
  //   print("SECURITY CONTEXT SET");
  // } catch (e) {
  //   print("SECURITY CONTEXT ERROR: $e");
  // }

  await NotificationService().init();
  FCM().setNotifications();
  setupLocator();
  runApp(
    Phoenix(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();

  static MyAppState? of(BuildContext context) => context.findAncestorStateOfType<MyAppState>();
}

class MyAppState extends State<MyApp> {
  bool pinUsed = false;
  String? initRoute;
  var ms = '';
  AppDatabase db = GetIt.I.get<AppDatabase>();

  Future<String> get jwtOrEmpty async {
    precache();
    await getPin();
    var mJWT = await SecureStorage.read(key: globals.TOKEN);
    if (mJWT == null) {
      FlutterNativeSplash.remove();
      return LoginPage.route;
    } else {
      var jwt = mJWT.split(".");
      if (jwt.length != 3) {
        FlutterNativeSplash.remove();
        return LoginPage.route;
      } else {
        bool res = await NetInterface.daoLogin();
        if (res) {
         debugPrint("Dao Login OK");
        } else {
          debugPrint('Dao login failed');
        }
        FlutterNativeSplash.remove();
        var payload = json.decode(ascii.decode(base64.decode(base64.normalize(jwt[1]))));
        if (DateTime.fromMillisecondsSinceEpoch(payload["exp"] * 1000).isAfter(DateTime.now())) {
          if (pinUsed) {
            return AuthScreen.route;
          } else {
            return MainMenuNew.route;
          }
        } else {
          FlutterNativeSplash.remove();
          return LoginPage.route;
        }
      }
    }
  }

  Future getPinFuture() async {
    var s = SecureStorage.read(key: globals.PIN);
    return s;
  }

  precache() {
    precacheImage(const AssetImage('images/logo.png'), context);
    precacheImage(const AssetImage('images/logo_send.png'), context);
    precacheImage(const AssetImage('images/wallet_big.png'), context);
    precacheImage(const AssetImage('images/staking_big.png'), context);
    precacheImage(const AssetImage('images/messages_big.png'), context);
    precacheImage(const AssetImage('images/contacts_big.png'), context);
    precacheImage(const AssetImage('images/settings_big.png'), context);
    precacheImage(const AssetImage('images/card.png'), context);
    precacheImage(const AssetImage('images/test_pattern.png'), context);
  }

  getPin() async {
    final String? pin = await getPinFuture();
    if (pin != null) pinUsed = true;
  }

  void _getSetLang() async {
    String? ll = await SecureStorage.read(key: globals.LOCALE_APP);
    if (ll != null) {
      Locale l;
      List<String> ls = ll.split('_');
      if (ls.length == 1) {
        l = Locale(ls[0], '');
      } else if (ls.length == 2) {
        l = Locale(ls[0], ls[1]);
      } else {
        l = Locale.fromSubtags(countryCode: ls[2], scriptCode: ls[1], languageCode: ls[0]);
      }
      setLocale(l);
    }
  }

  @override
  void initState() {
    _setOptimalDisplayMode();
    super.initState();
    _getSetLang();
   _manageStorage();
  }

  void _manageStorage() async {
    // SecureStorage.deleteStorage(key: globals.TOKEN_DAO);
    String? s = await SecureStorage.read(key: 'nextgen');
    if (s == null || s == "1") {
      SecureStorage.deleteAllStorage();
      AppDatabase().deleteTableAddr();
      AppDatabase().deleteTableMessages();
      AppDatabase().deleteTableMgroup();
      AppDatabase().deleteTableTran();
      await SecureStorage.write(key: 'nextgen', value: "2");
    }
  }

  Locale? _locale;

  void setLocale(Locale value) {
    Future.delayed(Duration.zero, () {
      setState(() {
        _locale = value;
      });
    });
  }

  Future<void> _setOptimalDisplayMode() async {
    try {
      final List<DisplayMode> supported = await FlutterDisplayMode.supported;
      final DisplayMode active = await FlutterDisplayMode.active;

      final List<DisplayMode> sameResolution = supported.where((DisplayMode m) => m.width == active.width && m.height == active.height).toList()
        ..sort((DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate));

      final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : active;

      await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: jwtOrEmpty,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MaterialApp(
              locale: _locale,
              title: 'DigitalNote APP',
              onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
              onGenerateRoute: generateRoute,
              initialRoute: snapshot.data as String,
              routes: {
                LoginPage.route: (context) => const LoginPage(),
                RegisterScreen.route: (context) => const RegisterScreen(),
                MainMenuNew.route: (context) => MainMenuNew(locale: ms),
                // AuthScreen.route: (context) => const AuthScreen(),
                // WalletScreen.route : (context) =>  WalletScreen(arguments: ModalRoute.of(context)!.settings.arguments!,),
              },
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              localeListResolutionCallback: (locales, supportedLocales) {
                ms = 'device locales=$locales supported locales=$supportedLocales';
                for (Locale locale in locales!) {
                  if (supportedLocales.contains(locale)) {
                    return locale;
                  }
                }
                return const Locale('en', '');
              },
              supportedLocales: const [
                Locale('cs', 'CZ'),
                Locale('en', ''),
                Locale('fi', 'FI'),
                Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl', countryCode: 'RS'),
                Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn', countryCode: 'RS'),
                Locale('sr', 'RS'),
                Locale('hr', 'HR'),
                Locale('bs', 'BA'),
                Locale('ja', 'JP'),
                Locale.fromSubtags(languageCode: 'bs', scriptCode: 'Latn', countryCode: 'BA'),
                Locale('hi', 'IN'),
                Locale('hi', 'FJ'),
                Locale('de', 'DE'),
                Locale('de', 'AT'),
                Locale('pa', 'IN'),
                Locale('pa', 'PK'),
                Locale('uk', 'UA'),
                Locale('ru', 'UA'),
                Locale('es', 'AR'),
                Locale('es', 'BO'),
                Locale('es', 'CL'),
                Locale('es', 'CO'),
                Locale('es', 'CU'),
                Locale('es', 'DO'),
                Locale('es', 'EC'),
                Locale('es', 'ES'),
                Locale('es', 'GT'),
                Locale('es', 'HN'),
                Locale('es', 'MX'),
                Locale('es', 'NI'),
                Locale('es', 'PA'),
                Locale('es', 'PE'),
                Locale('es', 'PR'),
                Locale('es', 'PY'),
                Locale('es', 'SV'),
                Locale('es', 'US'),
                Locale('es', 'UY'),
                Locale('es', 'VE'),
                Locale('nl', 'NL'),
                Locale('nl', 'BE'),
                Locale('nl', 'AW'),
              ],
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                fontFamily: 'lato',
                useMaterial3: true,
                canvasColor: const Color(0xFF28303F),
                primaryColor: generateMaterialColor(Colors.white),
                primarySwatch: generateMaterialColor(const Color.fromRGBO(44, 44, 53, 1.0)),
                textTheme: TextTheme(
                    headline6: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontWeight: FontWeight.w200,
                    ),
                    headline5: GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.w300, letterSpacing: 1.0),
                    subtitle1: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                    subtitle2: GoogleFonts.montserrat(
                      color: const Color(0xFFC6C6C6),
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                    headline1: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 40.0,
                    ),
                    bodyText1: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontSize: 24.0,
                    ),
                    bodyText2: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontSize: 18.0,
                    ),
                    button: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w200,
                      fontSize: 18.0,
                    )), textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Colors.white,
                selectionColor: Colors.blue,
                selectionHandleColor: Colors.blue,
              ),
              ),
              home: const BackgroundWidget(mainMenu: true),
            );
          } else {
            return Container();
          }
        });
  }

  Route<dynamic> generateRoute(RouteSettings settings) {
    var uri = Uri.parse(settings.name!);
    switch (uri.path) {
      case WalletScreen.route:
        Object? shit = settings.arguments;
        return MaterialPageRoute(
            builder: (_) => WalletScreen(
                  arguments: shit!,
                ));
      case AddressScreen.route:
        return MaterialPageRoute(builder: (_) => const AddressScreen());
      case StakingScreen.route:
        return MaterialPageRoute(builder: (_) => const StakingScreen());
      case MessageScreen.route:
        return MaterialPageRoute(builder: (_) => const MessageScreen());
      case SettingsScreen.route:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case SecurityScreen.route:
        return MaterialPageRoute(builder: (_) => const SecurityScreen());
      case VotingScreen.route:
        return MaterialPageRoute(builder: (_) => const VotingScreen());
      case TokenScreen.route:
        return MaterialPageRoute(builder: (_) => const TokenScreen());
      case AuthScreen.route:
        Object? args = settings.arguments;
        if (args != null) {
          Map<String, dynamic> m = args as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) => AuthScreen(
                    setupPIN: m['bl'],
                    type: m['type'],
                  ));
        } else {
          return MaterialPageRoute(builder: (_) => const AuthScreen(type: 0));
        }
      case BlockInfoScreen.route:
        return MaterialPageRoute(builder: (_) => const BlockInfoScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
