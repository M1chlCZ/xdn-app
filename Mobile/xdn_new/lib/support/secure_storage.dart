import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {


  static Future<String?> read({required String key}) {
    try {
      const FlutterSecureStorage mstorage = FlutterSecureStorage();
      const optionsApple = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
      const optionsAndroid = AndroidOptions(encryptedSharedPreferences: true);
      const webOptions = WebOptions(dbName: "CNliCGCAgu", publicKey: "6i81ge6Fc3bqgxbtc1Wl");
      return  mstorage.read(key: key, iOptions: optionsApple, aOptions: optionsAndroid);
    } catch (e) {
      print(e);
      return Future.value(null);
    }
  }

  static Future<void> write({required String key,required String value}) {
    try {
      const FlutterSecureStorage mstorage = FlutterSecureStorage();
      const optionsApple = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
      const optionsAndroid = AndroidOptions(encryptedSharedPreferences: true);
      return  mstorage.write(key: key, value: value, iOptions: optionsApple, aOptions: optionsAndroid);
    } catch (e) {
      print(e);
      return Future.value(null);
    }

  }

  static Future<void> deleteStorage({required String key}) {
    try {
      const FlutterSecureStorage mstorage = FlutterSecureStorage();
      const optionsApple = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
      const optionsAndroid = AndroidOptions(encryptedSharedPreferences: true);
      return   mstorage.delete(key: key, iOptions: optionsApple, aOptions: optionsAndroid);
    } catch (e) {
      print(e);
      return Future.value(null);
    }
  }

  static Future<void> deleteAllStorage() {
    try {
      const FlutterSecureStorage mstorage = FlutterSecureStorage();
      const optionsApple = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
      const optionsAndroid = AndroidOptions(encryptedSharedPreferences: true);
      return   mstorage.deleteAll(iOptions: optionsApple, aOptions: optionsAndroid);
    } catch (e) {
      print(e);
      return Future.value(null);
    }
  }

}