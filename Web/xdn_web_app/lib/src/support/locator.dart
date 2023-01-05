import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:http/io_client.dart';

GetIt locator = GetIt.instance;

void setupLocator() async {
  // SecurityContext(withTrustedRoots: false);
  // ByteData data = await rootBundle.load("assets/cert.pem");
  SecurityContext context = SecurityContext.defaultContext;
  // context.setTrustedCertificatesBytes(data.buffer.asUint8List());
  final httpClient = HttpClient(context: context);


  try {
    // locator.registerLazySingleton<FCM>(() => FCM());
    // locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
    // locator.registerLazySingleton<WalletConnector>(() => BSCConnector());
    // locator.registerLazySingleton<WXDConnector>(() => WXDConnector());
    locator.registerFactoryAsync<IOClient>(() async {
        return IOClient(httpClient);
      });
  } catch (e) {
    debugPrint(e.toString());
  }
}