// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xdn_dex/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
   const FlutterSecureStorage fs = FlutterSecureStorage(webOptions: WebOptions(
      dbName: "CNliCGCAgu",
      publicKey: "6i81ge6Fc3bqgxbtc1Wl",
    ));
    await tester.pumpWidget(const MyApp(sharedPreferences: fs,));
  });
}
