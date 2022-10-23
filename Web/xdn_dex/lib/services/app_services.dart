import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xdn_dex/support/extensions.dart';

String LOGIN_KEY = "5FD6G46SDF4GD64F1VG9SD68";
String ONBOARD_KEY = "GD2G82CG9G82VDFGVD22DVG";

class AppService with ChangeNotifier {
  late final FlutterSecureStorage sharedPreferences;
  final StreamController<bool> _loginStateChange = StreamController<bool>.broadcast();
  bool _loginState = false;
  bool _initialized = false;
  bool _onboarding = false;

  AppService(this.sharedPreferences);

  bool get loginState => _loginState;
  bool get initialized => _initialized;
  bool get onboarding => _onboarding;
  Stream<bool> get loginStateChange => _loginStateChange.stream;

  set loginState(bool state) {
    sharedPreferences.write(key: LOGIN_KEY, value: state.toString());
    _loginState = state;
    _loginStateChange.add(state);
    notifyListeners();
  }

  set initialized(bool value) {
    _initialized = value;
    notifyListeners();
  }

  set onboarding(bool value) {
    sharedPreferences.write(key: ONBOARD_KEY, value: value.toString());
    _onboarding = value;
    notifyListeners();
  }

  Future<void> onAppStart() async {
    String? onBoard = await sharedPreferences.read(key: ONBOARD_KEY);
    String? loginKey = await sharedPreferences.read(key: LOGIN_KEY);
    _onboarding = onBoard.parseBool() ?? false;
    _loginState = loginKey.parseBool() ?? false;

    print("onboarding: $_onboarding");
    print("loginState: $_loginState");

    // This is just to demonstrate the splash screen is working.
    // In real-life applications, it is not recommended to interrupt the user experience by doing such things.
    // await Future.delayed(const Duration(seconds: 2));

    _initialized = true;
    notifyListeners();
  }
}