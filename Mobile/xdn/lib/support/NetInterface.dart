import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

import '../globals.dart' as globals;
import 'AppDatabase.dart';
import 'Contact.dart';
import 'Dialogs.dart';
import 'Encrypt.dart';
import 'Message.dart';
import 'MessageGroup.dart';
import 'TranSaction.dart';

class NetInterface {
  static void uploadPicture(BuildContext context, String base64) async {
    const storage = FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param1": base64,
        "param2": "upload",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      Response response = await http
          .post(
            Uri.parse(globals.SERVER_URL + '/apiAvatar'),
            body: {
              "Content-Type": "application/json",
              "payload": s,
            },
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            encoding: Encoding.getByName('utf-8'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
      } else {
        // Dialogs.openAlertBox(context, 'Warning', response.toString());
      }
    } on TimeoutException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Request timed out, can't save the picture to cloud");
    } on SocketException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Service is not available, can't save the picture to cloud");
    } catch (e) {
      print(e.toString());
      Dialogs.openAlertBox(context, 'Warning', e.toString());
    }
  }

  static Future<Uint8List?> downloadCSV(BuildContext context) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.USERNAME);

      Map<String, dynamic> m = {"Authorization": jwt, "User": id, "request": "getcsv"};

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        return base64.decode(data);
      } else {
        Dialogs.openAlertBox(context, 'Error', response.toString());
        return null;
      }
    } on TimeoutException catch (_) {
      Dialogs.openAlertBox(context, 'Error', "Request timed out, can't save the picture to cloud");
      return null;
    } on SocketException catch (_) {
      Dialogs.openAlertBox(context, 'Error', "Service is not available, can't save the picture to cloud");
      return null;
    } catch (e) {
      print(e.toString());
      Dialogs.openAlertBox(context, 'Error', e.toString());
      return null;
    }
  }

  static Future<String?> dowloadPicture(BuildContext context, int? userID) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param1": userID ?? 0,
        "param2": "download",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http
          .post(
            Uri.parse(globals.SERVER_URL + '/apiAvatar'),
            body: {
              "Content-Type": "application/json",
              "payload": s,
            },
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            encoding: Encoding.getByName('utf-8'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Dialogs.openAlertBox(context, 'Warning', response.toString());
        return null;
      }
    } on TimeoutException catch (_) {
      // Dialogs.openAlertBox(context, 'Warning',
      //     "Request timed out, can't save the picture to cloud");
      return null;
    } on SocketException catch (_) {
      // Dialogs.openAlertBox(context, 'Warning',
      //     "Service is not available, can't save the picture to cloud");
      return null;
    } catch (e) {
      print(e.toString());
      // Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<String?> dowloadPictureByAddr(BuildContext context, String addr) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param1": addr,
        "param2": "download",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http
          .post(
            Uri.parse(globals.SERVER_URL + '/apiAvatar'),
            body: {
              "Content-Type": "application/json",
              "payload": s,
            },
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            encoding: Encoding.getByName('utf-8'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Dialogs.openAlertBox(context, 'Warning', response.toString());
        return null;
      }
    } on TimeoutException catch (_) {
      // Dialogs.openAlertBox(context, 'Warning',
      //     "Request timed out, can't save the picture to cloud");
      return null;
    } on SocketException catch (_) {
      // Dialogs.openAlertBox(context, 'Warning',
      //     "Service is not available, can't save the picture to cloud");
      return null;
    } catch (e) {
      print(e.toString());
      // Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<void> registerFirebaseToken(String token) async {
    var storage = const FlutterSecureStorage();
    String? jwt = await storage.read(key: "jwt");
    String? id = await storage.read(key: globals.ID);

    Map<String, dynamic> m = {"Authorization": jwt, "id": id, "param1": token, "param2": Platform.isAndroid ? "A" : "I", "request": "registerFirebaseToken"};

    try {
      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // print("shit saved");
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
    } on SocketException catch (_) {
      print('No internet');
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<int> getTranData() async {
    var storage = const FlutterSecureStorage();
    String? jwt = await storage.read(key: "jwt");
    String? user = await storage.read(key: globals.USERNAME);
    String? locale = await storage.read(key: globals.LOCALE);
    Map<String, dynamic> m = {
      "Authorization": jwt,
      "User": user,
      "param1": locale,
      "request": "getTransaction",
    };
    try {
      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var l = await compute(getTransactionCompute, response.body);
        await AppDatabase().addTransactions(l);
        return 1;
      } else {
        print("err.");
        return 0;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      print('No internet');
      return 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  static List<TranSaction> getTransactionCompute(String response) {
    var data = decryptAESCryptoJS(response, "rp9ww*jK8KX_!537e%Crmf");

    List responseList = json.decode(data);
    List<TranSaction> l = responseList.map((data) => TranSaction.fromJson(data)).toList();
    return l;
  }

  static Future<String?> getBalance({bool details = false}) async {
    var storage = const FlutterSecureStorage();
    String? jwt = await storage.read(key: "jwt");
    String? user = await storage.read(key: globals.USERNAME);
    Map<String, dynamic> m;
    if (details) {
      m = {"Authorization": jwt, "User": user, "param1": 1, "request": "getBalance"};
    } else {
      m = {"Authorization": jwt, "User": user, "request": "getBalance"};
    }
    var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
    try {
      var response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        return data;
      } else {
        return "err.";
      }
    } on SocketException catch (_) {
      return Future.error('No internet');
    } on TimeoutException catch (_) {
      return Future.error('Service unreachable');
    } catch (e) {
      return Future.error("err.");
    }
  }

  static Future<void> getAddrBook() async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "request": "getAddrBook",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        List responseList = json.decode(data);
        List<Contact> l = responseList.map((data) => Contact.fromJson(data)).toList();
        AppDatabase().addAddrBook(l);
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
    } on SocketException catch (_) {
      print('No internet');
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<int> saveContact(String name, String addr, BuildContext context) async {
    if (addr.length != 34 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(addr) || addr[0] != 'K') {
      Dialogs.openAlertBox(context, "Error", "Invalid KONJ address");
      return 0;
    }

    if (name.isEmpty) {
      Dialogs.openAlertBox(context, "Error", "Name cannot be empty");
      return 0;
    }

    try {
      Navigator.of(context).pop();
      Dialogs.openWaitBox(context);
      var storage = const FlutterSecureStorage();
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "request": "saveAdrrBook",
        "param1": name,
        "param2": addr,
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List responseList = json.decode(response.body);
        List<Contact> l = responseList.map((data) => Contact.fromJson(data)).toList();
        var db = await AppDatabase().addAddrBook(l);
        if (db == 1) {
          return 1;
        }
        return 0;
      } else {
        print("problemo");
        return 0;
      }
    } on TimeoutException catch (_) {
      print("Timeout");
      return 0;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  static Future<void> saveMessageGroup() async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? addr = await storage.read(key: globals.ADR);
      String? timez = await storage.read(key: globals.LOCALE);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "param1": addr,
        "param2": timez,
        "request": "getMessageGroup",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        List<MessageGroup>? l = await compute(parseMessagesGroup, response.body);
        await AppDatabase().addMessageGroup(l!);
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
    } on SocketException catch (_) {
      print('No internet');
    } catch (e) {
      print(e.toString());
    }
  }

  static List<MessageGroup>? parseMessagesGroup(String body) {
    try {
      var data = decryptAESCryptoJS(body.toString(), "rp9ww*jK8KX_!537e%Crmf");
      List responseList = json.decode(data);
      List<MessageGroup> l = responseList.map((data) => MessageGroup.fromJson(data)).toList();
      return l;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<int> saveMessages(String address, int idMax) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? addr = await storage.read(key: globals.LOCALE);
      String? addr2 = await storage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": idMax,
        "param1": address,
        "param2": addr,
        "param3": addr2,
        "request": "getMessages",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        try {
          // var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
          // print(data);
          final l = await compute(parseMessages, response.body);
          int i = await AppDatabase().addMessages(l!);
          return i;
        } catch (e) {
          print(e);
          return 0;
        }
      }
      return 0;
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      print('No internet');
      return 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  static List<Message>? parseMessages(String body) {
    try {
      var data = decryptAESCryptoJS(body.toString(), "rp9ww*jK8KX_!537e%Crmf");
      List responseList = json.decode(data);
      List<Message> l = responseList.map((data) => Message.fromJson(data)).toList();
      return l;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> updateRead(String address) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? addr = await storage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "param1": address,
        "param2": addr,
        "request": "updateRead",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await AppDatabase().updateMessageGroupRead(addr!, address);
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
    } on SocketException catch (_) {
      print('No internet');
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<int> updateLikes(int id) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? addr = await storage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param": addr,
        "request": "updateLikes",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        Map m = json.decode(data);
        int i = int.parse(m['likes'].toString().trim());
        await AppDatabase().updateMessageLikes(id, i);
        return i;
      }else{
        return 0;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      print('No internet');
      return 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  static Future<void> updateContact(String name, String id) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "param1": id,
        "param2": name,
        "request": "updateContact",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        // AppDatabase().updateMessageGroupRead(addr, address);
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
    } on SocketException catch (_) {
      print('No internet');
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<void> sendMessage(String address, String text, int idReply) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? addr = await storage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": idReply,
        "param1": addr,
        "param2": address,
        "param3": text,
        "request": "sendMessage",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await AppDatabase().updateMessageGroupRead(addr!, address);
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
    } on SocketException catch (_) {
      print('No internet');
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<int> sendContactCoins(String amount, String name, String addr) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);
      String? user = await storage.read(key: globals.USERNAME);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "User": user,
        "id": id,
        "request": "sendContactTransaction",
        "param1": addr,
        "param2": amount,
        "param3": name,
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return 1;
      } else {
        return 2;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      print('No internet');
      return 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  static Future<int> sendStakeCoins(String amount) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);
      String? user = await storage.read(key: globals.USERNAME);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "User": user,
        "id": id,
        "request": "setStake",
        "param1": amount,
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return 1;
      } else if (response.statusCode == 400) {
        return 2;
      } else if (response.statusCode == 407) {
        return 4;
      } else {
        return 3;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      print('No internet');
      return 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  static Future<int> unstakeCoins(int type) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param1": type,
        "request": "unstake",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return 1;
      } else {
        return 2;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      print('No internet');
      return 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  static Future<Map<String, dynamic>?> getAdminNickname() async {
    var storage = const FlutterSecureStorage();
    String? jwt = await storage.read(key: "jwt");
    String? id = await storage.read(key: globals.ID);
    Map<String, dynamic> m = {"Authorization": jwt, "id": id, "request": "getAdminNickname"};
    try {
      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        Map<String, dynamic> map = json.decode(data);
        return map;
      } else {
        return null;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return null;
    } on SocketException catch (_) {
      print('No internet');
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  static Future<bool> checkPassword(String password) async {
    var storage = const FlutterSecureStorage();
    String? username = await storage.read(key: globals.USERNAME);
    try {
      Map<String, dynamic> m = {
        "username": username,
        "password": password,
      };
      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      var res = await http.post(Uri.parse(globals.SERVER_URL + "/login"), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return false;
    } on SocketException catch (_) {
      print('No internet');
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  static Future<String?> getPrivKey() async {
    var storage = const FlutterSecureStorage();
    String? addr = await storage.read(key: globals.ADR);
    String? jwt = await storage.read(key: "jwt");
    try {
      Map<String, dynamic> m = {"Authorization": jwt, "param1": addr, "request": "getPrivKey"};

      final res = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        String? data = decryptAESCryptoJS(res.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        return data;
      } else {
        return null;
      }
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return null;
    } on SocketException catch (_) {
      print('No internet');
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  static void renameUser(BuildContext context, String nickname) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    try {
      if (nickname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Name cannot be empty!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
        Navigator.of(context).pop();
      } else {
        const storage = FlutterSecureStorage();
        String? jwt = await storage.read(key: "jwt");
        String? id = await storage.read(key: globals.ID);

        Map<String, dynamic> m = {
          "Authorization": jwt,
          "id": id,
          "param1": nickname,
          "request": "renameUser",
        };

        var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
        final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
          "Content-Type": "application/json",
          "payload": s,
        }).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          globals.reloadData = true;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Your nickname has been changed!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            elevation: 5.0,
          ));
          var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
          Map<String, dynamic> map = json.decode(data);
          await storage.write(key: globals.NICKNAME, value: map['nick']);
        } else {
          Navigator.of(context).pop();
          Dialogs.openAlertBox(context, 'Warning', 'Server error');
        }
      }
    } on TimeoutException catch (_) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', 'Request timed out');
    } on SocketException catch (_) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', 'Service unavailable');
    } catch (e) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', e.toString());
    }
  }

  static void changePassword(BuildContext context, String pass) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    try {
      const storage = FlutterSecureStorage();
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param1": pass,
        "request": "changePassword",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Your password has been changed!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      } else {
        Navigator.of(context).pop();
        Dialogs.openAlertBox(context, 'Error', 'Password has not been changed');
      }
    } on TimeoutException catch (_) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', 'Request timed out');
    } on SocketException catch (_) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', 'Service unavailable');
    } catch (e) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', e.toString());
    }
  }

  static Future<int> getAvatarVersion(String? addr) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "param1": addr,
        "request": "avatarVersion",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        Map reponseMap = json.decode(data);
        return AppDatabase().insertUpdateAvatar(reponseMap['addr'], reponseMap['version']);
      }
      return 0;
    } on TimeoutException catch (_) {
      print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      print('No internet');
      return 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  static Future<String?> getRewardsByDay(BuildContext context, String date, int type) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);
      String? tz = await storage.read(key: globals.LOCALE);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param1": date,
        "param2": type,
        "param3": tz,
        "request": "getRewards",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        return data.toString();
      } else {
        Dialogs.openAlertBox(context, 'Warning', response.toString());
        return null;
      }
    } on TimeoutException catch (_) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', "Request timed out");
      return null;
    } on SocketException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Service is not available");
      return null;
    } catch (e) {
      print(e.toString());
      Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<String?> getRewardsByMonth(BuildContext context, String year, String month, int type) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "param1": year,
        "param2": type,
        "param3": month,
        "request": "getRewards",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        return data.toString();
      } else {
        Dialogs.openAlertBox(context, 'Warning', response.toString());
        return null;
      }
    } on TimeoutException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Request timed out");
      return null;
    } on SocketException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Service is not available");
      return null;
    } catch (e) {
      print(e.toString());
      Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<Map?> getPoolStats(BuildContext context) async {
    var storage = const FlutterSecureStorage();
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      Map<String, dynamic> m = {"Authorization": jwt, "id": id, "request": "getPoolStats"};

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        Map reponseMap = json.decode(data);
        return reponseMap;
      } else {
        // Dialogs.openAlertBox(context, 'Error', response.body.toString());
        return null;
      }
    } on TimeoutException catch (_) {
      // Dialogs.openAlertBox(context, 'Error',
      //     "Request timed out, can't save the picture to cloud");
      return null;
    } on SocketException catch (_) {
      // Dialogs.openAlertBox(context, 'Error',
      //     "Service is not available, can't save the picture to cloud");
      return null;
    } catch (e) {
      print(e.toString());
      // Dialogs.openAlertBox(context, 'Error', e.toString());
      return null;
    }
  }
}
