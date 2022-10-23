import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xdn_dex/router/app_router.dart';
import 'package:xdn_dex/services/app_services.dart';
import 'package:xdn_dex/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  const FlutterSecureStorage fs = FlutterSecureStorage(webOptions: WebOptions(
    dbName: "CNliCGCAgu",
    publicKey: "6i81ge6Fc3bqgxbtc1Wl",
  ));
  runApp(const MyApp(sharedPreferences: fs,));
}

class MyApp extends StatefulWidget {
  final FlutterSecureStorage sharedPreferences;
  const MyApp({super.key, required this.sharedPreferences});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppService appService;
  late AuthService authService;
  late StreamSubscription<bool> authSubscription;

  @override
  void initState() {
    appService = AppService(widget.sharedPreferences);
    authService = AuthService();
    authSubscription = authService.onAuthStateChange.listen(onAuthStateChange);
    super.initState();
  }

  void onAuthStateChange(bool login) {
    appService.loginState = login;
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppService>(create: (_) => appService),
        Provider<AppRouter>(create: (_) => AppRouter(appService)),
        Provider<AuthService>(create: (_) => authService),
      ],
      child: Builder(
        builder: (context) {
          final GoRouter goRouter = Provider.of<AppRouter>(context, listen: false).router;
          return MaterialApp.router(
            title: "XDN DEX",
            theme: ThemeData(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                  TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            routeInformationProvider: goRouter.routeInformationProvider,
            routeInformationParser: goRouter.routeInformationParser,
            routerDelegate: goRouter.routerDelegate,
          );
        },
      ),
    );
  }
}