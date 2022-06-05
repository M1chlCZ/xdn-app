import 'dart:convert';

import 'package:digitalnote/screens/addrScreen.dart';
import 'package:digitalnote/screens/main_menu.dart';
import 'package:digitalnote/screens/messagescreen.dart';
import 'package:digitalnote/screens/registerscreen.dart';
import 'package:digitalnote/screens/stakingScreen.dart';
import 'package:digitalnote/screens/walletscreen.dart';
import 'package:digitalnote/support/secure_storage.dart';
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

import 'firebase_options.dart';
import 'globals.dart' as globals;
import 'screens/loginscreen.dart';
import 'screens/mainMenuScreen.dart';
import 'screens/pinscreen.dart';
import 'support/MaterialColorGenerator.dart';
import 'widgets/BackgroundWidget.dart';

bool pinUsed = false;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  bool b = await FlutterAppBadger.isAppBadgeSupported();
  if (b) {
    FlutterAppBadger.updateBadgeCount(1);
  }
  SecureStorage.write(key: globals.APP_NOT, value: "yes");
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
  MyAppState createState() => MyAppState();

  static MyAppState? of(BuildContext context) => context.findAncestorStateOfType<MyAppState>();
}

class MyAppState extends State<MyApp> {
  bool pinUsed = false;
  String? initRoute;
  var ms = '';

  Future<String> get jwtOrEmpty async {
    await getPin();
       var mJWT = await SecureStorage.read(key: globals.TOKEN);
    if (mJWT == null) {
      return LoginPage.route;
    }else{
      var jwt = mJWT.split(".");
      if (jwt.length != 3) {
        return LoginPage.route;
      } else {
        var payload = json.decode(ascii.decode(base64.decode(base64.normalize(jwt[1]))));
        if (DateTime.fromMillisecondsSinceEpoch(payload["exp"] * 1000).isAfter(DateTime.now())) {
          if (pinUsed) {
            return PinScreen.route;
          } else {
            return MainMenuNew.route;
          }
        } else {
          return LoginPage.route;
        }
      }
    }

  }

  Future getPinFuture() async {
    var s = SecureStorage.read(key: globals.PIN);
    return s;
  }

  getPin() async {
    final String? pin = await getPinFuture();
    if (pin != null) pinUsed = true;
  }


  void _getSetLang() async {
    if (mounted) await precacheImage(const AssetImage('images/wendyicon.png'), context);
    if (mounted) await precacheImage(const AssetImage('images/menubutton.png'), context);
    if (mounted) await precacheImage(const AssetImage('images/konjicon.png'), context);
    if (mounted) await precacheImage(const AssetImage('images/mainmenubg.png'), context);
    if (mounted) await precacheImage(const AssetImage('images/QR.png'), context);

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
    // storage.deleteAll();
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
      builder:(context, snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
            locale: _locale,
            title: 'Konjungate APP',
            onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context)!.appTitle,
            onGenerateRoute:  generateRoute,
            initialRoute: snapshot.data as String,
            routes: {
              LoginPage.route: (context) => const LoginPage(),
              RegisterScreen.route: (context) => const RegisterScreen(),
              MainMenuNew.route: (context) => MainMenuNew(locale: ms),
              PinScreen.route: (context) => const PinScreen(),
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
              fontFamily: 'lato',
              useMaterial3: true,
              canvasColor: const Color(0xFF423D70),
              primaryColor: generateMaterialColor(Colors.white),
              primarySwatch: generateMaterialColor(const Color.fromRGBO(44, 44, 53, 1.0)),
              textTheme: TextTheme(
                  headline6: GoogleFonts.lato(
                    color: Colors.white70,
                    fontWeight: FontWeight.w200,
                  ),
                  headline5: GoogleFonts.lato(
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3.0
                  ),
                  subtitle1: GoogleFonts.lato(
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                  subtitle2: GoogleFonts.lato(
                    color: const Color(0xFFC6C6C6),
                    fontSize: 14.0,
                    fontWeight: FontWeight.normal,
                  ),
                  headline1: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 40.0,
                  ),
                  bodyText1: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 24.0,
                  ),
                  bodyText2: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 18.0,
                  ),
                  button: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w200,
                    fontSize: 18.0,
                  )),
            ),
            home: const BackgroundWidget(mainMenu: true),
          );
        }else{
          return Container();
      }
    }
    );
  }

  Route<dynamic> generateRoute(RouteSettings settings) {
    var uri = Uri.parse(settings.name!);
    switch (uri.path) {
      case WalletScreen.route:
        Object? shit = settings.arguments;
        return MaterialPageRoute(
            builder: (_) => WalletScreen(arguments: shit!,));
      case MainMenuNew.route:
        return MaterialPageRoute(
            builder: (_) => const MainMenuNew(
            ));
      case AddressScreen.route:
          return MaterialPageRoute(
              builder: (_) => const AddressScreen());
      case StakingScreen.route:
        return MaterialPageRoute(
            builder: (_) => const StakingScreen());
      case MessageScreen.route:
        return MaterialPageRoute(
            builder: (_) => const MessageScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
