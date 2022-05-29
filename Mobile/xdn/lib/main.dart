import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'globals.dart' as globals;
import 'screens/loginscreen.dart';
import 'screens/mainMenuScreen.dart';
import 'screens/pinscreen.dart';
import 'support/MaterialColorGenerator.dart';
import 'widgets/BackgroundWidget.dart';

const storage = FlutterSecureStorage();
bool pinUsed = false;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  var storage = const FlutterSecureStorage();
  bool b = await FlutterAppBadger.isAppBadgeSupported();
  if (b) {
    FlutterAppBadger.updateBadgeCount(1);
  }
  storage.write(key: globals.APP_NOT, value: "yes");
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );
  runApp(
    Phoenix(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();

}

class _MyAppState extends State<MyApp> {
  final storage = const FlutterSecureStorage();
  bool pinUsed = false;
  var ms= '';

  Future<String> get jwtOrEmpty async {
    await precacheImage(const AssetImage('images/wendyicon.png'), context);
    await precacheImage(const AssetImage('images/menubutton.png'), context);
    await precacheImage(const AssetImage('images/konjicon.png'), context);
    await precacheImage(const AssetImage('images/mainmenubg.png'), context);
    await precacheImage(const AssetImage('images/QR.png'), context);
    var jwt = await storage.read(key: "jwt");
    if (jwt == null) return "";
    return jwt;
  }

  Future getPinFuture() async {
    var s = storage.read(key: globals.PIN);
    return s;
  }

  void getPin() async {
    final String? pin = await getPinFuture();
    if (pin != null) pinUsed = true;
  }

  void _getSetLang() async {
    String? ll = await storage.read(key: globals.LOCALE_APP);
    if(ll != null) {
      Locale l;
      List<String> ls = ll.split('_');
      if(ls.length == 1) {
        l = Locale(ls[0], '');
      }else if (ls.length == 2) {
        l = Locale(ls[0], ls[1]);
      } else {
        l = Locale.fromSubtags(
            countryCode: ls[2], scriptCode: ls[1], languageCode: ls[0]);
      }
      setLocale(l);
    }
  }

  @override
  void initState() {
    _setOptimalDisplayMode();
    super.initState();
    _getSetLang();
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

      final List<DisplayMode> sameResolution = supported.where(
                  (DisplayMode m) => m.width == active.width
                  && m.height == active.height).toList()..sort(
                  (DisplayMode a, DisplayMode b) =>
                  b.refreshRate.compareTo(a.refreshRate));

      final DisplayMode mostOptimalMode = sameResolution.isNotEmpty
              ? sameResolution.first
              : active;

      await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    getPin();
    return MaterialApp(
      locale: _locale,
      title: 'Konjungate APP',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (locales, supportedLocales)  {
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
        Locale('fi','FI'),
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
        Locale('ru', 'RU'),
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
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        useMaterial3: true,
        primaryColor: generateMaterialColor(Colors.white),
        primarySwatch: generateMaterialColor(const Color.fromRGBO(44, 44, 53, 1.0)),
        textTheme: TextTheme(
            headline6: GoogleFonts.montserrat(
              color: Colors.white70,
              fontWeight: FontWeight.w200,
            ),
            headline5: GoogleFonts.montserrat(
              color: Colors.white70,
              fontWeight: FontWeight.w300,
            ),
            subtitle1: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.normal,
            ),
            subtitle2: const TextStyle(
              color: Color(0xFFC6C6C6),
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
            ),
            headline1: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 40.0,
            ),
            bodyText1: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 24.0,
            ),
            bodyText2: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18.0,
            ),
            button: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w200,
              fontSize: 18.0,
            )),
      ),
      home: FutureBuilder(
          future: jwtOrEmpty,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Stack(
              children: const [
                BackgroundWidget(mainMenu: true),
              ],
            );
            }
            if (snapshot.data != "") {
              String str = snapshot.data as String;
              var jwt = str.split(".");
              if (jwt.length != 3) {
                return const LoginPage();
              } else {
                var payload = json.decode(
                    ascii.decode(base64.decode(base64.normalize(jwt[1]))));
                if (DateTime.fromMillisecondsSinceEpoch(payload["exp"] * 1000)
                    .isAfter(DateTime.now())) {
                  if (pinUsed) {
                    return const PinScreen();
                  } else {
                    return MainMenuScreen(locale: ms);
                  }
                  // return PinPutTest();
                } else {
                  return const LoginPage();
                }
              }
            } else {
              return const LoginPage();
            }
          }),
    );
  }
}
