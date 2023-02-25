import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/bsc_connector.dart';
import 'package:digitalnote/support/notification_helper.dart';
import 'package:digitalnote/support/wallet_connector.dart';
import 'package:digitalnote/support/wxdn_connector.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

void setupLocator() async {
  try {
    locator.registerLazySingleton<FCM>(() => FCM());
    locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
    locator.registerLazySingleton<WalletConnector>(() => BSCConnector());
    locator.registerLazySingleton<WXDConnector>(() => WXDConnector());
  } catch (e) {
    debugPrint(e.toString());
  }
}
