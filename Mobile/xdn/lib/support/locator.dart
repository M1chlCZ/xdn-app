import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/bsc_connector.dart';
import 'package:digitalnote/support/notification_helper.dart';
import 'package:digitalnote/support/wallet_connector.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<FCM>(() => FCM());
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
  locator.registerLazySingleton<WalletConnector>(() => BSCConnector());
}