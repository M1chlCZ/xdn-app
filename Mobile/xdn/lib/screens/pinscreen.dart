import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:digitalnote/screens/mainMenuScreen.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';

import '../globals.dart' as globals;
import '../support/ColorScheme.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();
  final storage = const FlutterSecureStorage();
  bool isAuthenticated = false;
  late BuildContext b;
  bool showPinScreen = true;
  final bool _warningVisible = false;

  Future<void> showPin() async {
    Future.delayed(const Duration(milliseconds: 100), () {
      _showLockScreen(
        context,
        text: AppLocalizations.of(context)!.pin_enter,
        opaque: false,
        cancelButton: Text(
          AppLocalizations.of(context)!.cancel,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          semanticsLabel: AppLocalizations.of(context)!.cancel,
        ),
        keyboardUIConfig: const KeyboardUIConfig(),
        circleUIConfig: const CircleUIConfig(),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _verificationNotifier.close();
  }

  @override
  Widget build(BuildContext context) {
    b = context;
    if (isAuthenticated) {
      try {
        Future.delayed(Duration.zero, () {
          Navigator.maybePop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          );
        });
      } catch (e) {
        print(e);
      }
    } else {
      if (showPinScreen) {
        showPin();
      } else {
        showPinScreen = false;
      }
    }
    return Stack(children: const [
      BackgroundWidget(hasImage: false,),
    ]);
  }

  _showLockScreen(
    BuildContext context, {
    required String text,
    required bool opaque,
    required CircleUIConfig circleUIConfig,
    required KeyboardUIConfig keyboardUIConfig,
    required Widget cancelButton,
    // required List<String> digits,
  }) {
    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: opaque,
          pageBuilder: (context, animation, secondaryAnimation) =>
              PasscodeScreen(
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
            backgroundColor: Theme.of(context).konjHeaderColor,
            cancelCallback: _onPasscodeCancelled,
            // digits: digits,
            passwordDigits: 6,
            // bottomWidget: _buildPasscodeRestoreButton(),
          ),
        ));
  }

  _onPasscodeEntered(String enteredPasscode) async {
    var s = await storage.read(key: globals.PIN);
    bool isValid = enteredPasscode == s;
    _verificationNotifier.add(isValid);

    if (isValid) {
      setState(() {
        isAuthenticated = true;
      });
    }
  }

  _onPasscodeCancelled() {
    Navigator.of(context).pop();
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.pin_message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        elevation: 5.0,
      ));
    });
  }
}
