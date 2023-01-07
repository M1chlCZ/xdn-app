import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:xdn_web_app/src/exceptions/app_exception.dart';
import 'package:xdn_web_app/src/models/AppUser.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/support/memory_store.dart';
import 'package:xdn_web_app/src/support/secure_storage.dart';
import 'package:xdn_web_app/globals.dart' as globals;

class FakeAuthRepository {
  final _authState = InMemoryStore<AppUser?>(null);

  Stream<AppUser?> authStateChanges() => _authState.stream;
  AppUser? get currentUser => _authState.value;

  Future<void> signInWithEmailAndPassword(String email, String password, {String? pin}) async {
    Map<String, dynamic> m = {
      "username": email,
      "password": password,
    };
    if (pin != null) {
      m['twoFactor'] = pin;
    }

    ComInterface ci = ComInterface();
    Response res = await ci.post("/login",
        body: m,
        serverType: ComInterface.serverGoAPI,
        type: ComInterface.typePlain,
        debug: false);

    if (res.statusCode == 200) {
      Map<String, dynamic> r = json.decode(res.body.toString());
      var username = r["username"];
      var addr = r["addr"];
      var jwt = r["jwt"];
      var userID = r["userid"];
      var adminPriv = r["admin"];
      var nickname = r["nickname"];
      var tokenDao = r["token"];
      var refreshToken = r['refresh_token'];

      await SecureStorage.write(key: globals.USERNAME, value: username);
      await SecureStorage.write(key: globals.ADR, value: addr);
      await SecureStorage.write(key: globals.ID, value: userID.toString());
      await SecureStorage.write(key: globals.TOKEN, value: jwt);
      await SecureStorage.write(
          key: globals.ADMINPRIV, value: adminPriv.toString());
      await SecureStorage.write(
          key: globals.NICKNAME, value: nickname.toString());
      await SecureStorage.write(
          key: globals.TOKEN_DAO, value: tokenDao.toString());
      await SecureStorage.write(
          key: globals.TOKEN_REFRESH, value: refreshToken.toString());
      _authState.value = AppUser(
        uid: userID.toString(),
        email: email,
      );
    }else if (res.statusCode == 409) {
      throw const AppException.emailAlreadyInUse();
    }else if(res.statusCode == 404) {
      throw const AppException.wrongPassword();
    }
  }

  Future<void> createUserWithEmailAndPassword(
      String email, String password) async {
    if (currentUser == null) {
      _createNewUser(email);
    }
  }

  void checkIfLoggedIn() async{
    var s = await daoLogin();
     if (s == true) {
       print("SHIT");
      var id = await SecureStorage.read(key: globals.ID);
      var email = await SecureStorage.read(key: globals.USERNAME);
       _authState.value = AppUser(
         uid: id.toString(),
         email: email,
       );
     }else{
       print("double shit");
     }

  }

  Future<bool> daoLogin() async {
      ComInterface ci = ComInterface();
      Response r =  await ci.get("/ping", debug: true, serverType: ComInterface.serverDAO, type: ComInterface.typePlain, request: {});
      if (r.statusCode == 200) {
        return true;
      }else{
        return false;
      }
    }


  Future<void> signOut() async {
    // await Future.delayed(const Duration(seconds: 3));
    // throw Exception('Connection failed');
    _authState.value = null;
  }

  void dispose() => _authState.close();

  void _createNewUser(String email) {
    _authState.value = AppUser(
      uid: email.split('').reversed.join(),
      email: email,
    );
  }
}

final authRepositoryProvider = Provider<FakeAuthRepository>((ref) {
  final auth = FakeAuthRepository();
  ref.onDispose(() => auth.dispose());
  return auth;
});

final authStateChangesProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});