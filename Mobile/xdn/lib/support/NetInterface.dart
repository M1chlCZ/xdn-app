import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/secure_storage.dart';
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
    try {
      String? jwt = await SecureStorage.read(key: globals.TOKEN);
      String? id = await SecureStorage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "id": id,
        "param1": base64,
        "param2": "upload",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      Response response = await http
          .post(
            Uri.parse('${globals.SERVER_URL}/apiAvatar'),
            body: {
              "Content-Type": "application/json",
              "payload": s,
            },
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              "Authorization": jwt!,
            },
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
      if(kDebugMode)print(e.toString());
      Dialogs.openAlertBox(context, 'Warning', e.toString());
    }
  }

  static Future<Uint8List?> downloadCSV(BuildContext context) async {
    try {
      String? jwt = await SecureStorage.read(key: globals.TOKEN);
      String? id = await SecureStorage.read(key: globals.USERNAME);

      Map<String, dynamic> m = {"User": id, "request": "getcsv"};

      final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
        "Content-Type": "application/json",
        "Authorization": jwt!,
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
      if(kDebugMode)print(e.toString());
      Dialogs.openAlertBox(context, 'Error', e.toString());
      return null;
    }
  }

  static Future<String?> dowloadPicture(BuildContext context, int? userID) async {
    try {
      String? jwt = await SecureStorage.read(key: globals.TOKEN);
      String? id = await SecureStorage.read(key: globals.ID);
      Map<String, dynamic> m = {
        "id": id,
        "param1": userID ?? 0,
        "param2": "download",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http
          .post(
            Uri.parse('${globals.SERVER_URL}/apiAvatar'),
            body: {
              "Content-Type": "application/json",
              "payload": s,
            },
            headers: {"Content-Type": "application/x-www-form-urlencoded", "Authorization": jwt!},
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
      if(kDebugMode)print(e.toString());
      // Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }

  }

  static Future<String?> dowloadPictureByAddr(String addr) async {
    try {
      String? jwt = await SecureStorage.read(key: globals.TOKEN);
      String? id = await SecureStorage.read(key: globals.ID);
      Map<String, dynamic> m = {
        "id": id,
        "param1": addr,
        "param2": "download",
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http
          .post(
            Uri.parse('${globals.SERVER_URL}/apiAvatar'),
            body: {
              "Content-Type": "application/json",
              "payload": s,
            },
            headers: {"Content-Type": "application/x-www-form-urlencoded", "Authorization": jwt!},
            encoding: Encoding.getByName('utf-8'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        if(kDebugMode)print("sucks");
        // Dialogs.openAlertBox(context, 'Warning', response.toString());
        return null;
      }
    } catch (e) {
      if(kDebugMode)print(e.toString());
      // Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<void> registerFirebaseToken(String token) async {
    if(kDebugMode)print("FRRRRRRR");
    String? id = await SecureStorage.read(key: globals.ID);
    Map<String, dynamic> m = {"id": id, "param1": token, "param2": Platform.isAndroid ? "A" : "I", "request": "registerFirebaseToken"};

    ComInterface ci = ComInterface();
    try {
      await ci.get("/data", request: m, debug: false);

      // final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      // }).timeout(const Duration(seconds: 10));
      //
      // if (response.statusCode == 200) {
      //   // if(kDebugMode)print("shit saved");
      // }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
    } catch (e) {
      if(kDebugMode)print(e.toString());
    }
  }

  static Future<int> getTranData() async {
    String? user = await SecureStorage.read(key: globals.USERNAME);
    String? locale = await SecureStorage.read(key: globals.LOCALE);
    Map<String, dynamic> m = {
      "User": user,
      "param1": locale,
      "request": "getTransaction",
    };

    try {
      ComInterface ci = ComInterface();
      List<dynamic> rt = await ci.get("/data", request: m, type: ComInterface.typePlain);
      var l = await compute(getTransactionCompute, rt);
      var i = await AppDatabase().addTransactions(l);
      return i;
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return 0;
    }
  }

  static List<TranSaction> getTransactionCompute(List<dynamic> response) {
    List<TranSaction> l = response.map((data) => TranSaction.fromJson(data)).toList();
    return l;
  }

  static Future<Map<String, dynamic>>? getBalance({bool details = false}) async {
    String? user = await SecureStorage.read(key: globals.USERNAME);
    Map<String, dynamic> m;
    if (details) {
      m = {"User": user, "param1": 1, "request": "getBalance"};
    } else {
      m = {"User": user, "request": "getBalance"};
    }

    ComInterface ci = ComInterface();
    Map<String, dynamic> rt = await ci.get("/data", request: m);
    return rt;
  }

  static Future<int> getAddrBook() async {
    try {
      String? id = await SecureStorage.read(key: globals.ID);
      Map<String, dynamic> m = {
        "id": id,
        "request": "getAddrBook",
      };
      ComInterface ci = ComInterface();
      List<dynamic> rt = await ci.get("/data", request: m, debug: true);
      if (rt.isNotEmpty) {
        List<Contact> l = rt.map((l) => Contact.fromJson(l)).toList();
        AppDatabase().addAddrBook(l);
        return 1;
      }
      return 0;
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return 0;
    }
  }

  static Future<int> saveContact(String name, String addr, BuildContext context) async {
    if (addr.length != 34 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(addr) || addr[0] != 'd') {
      Dialogs.openAlertBox(context, "Error", "Invalid XDN address");
      return 0;
    }

    if (name.isEmpty) {
      Dialogs.openAlertBox(context, "Error", "Name cannot be empty");
      return 0;
    }

    try {

      String? id = await SecureStorage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "id": id,
        "request": "saveAdrrBook",
        "param1": name,
        "param2": addr,
      };


      // ComInterface ci = ComInterface();
      // List responseList = await ci.get("/data", request: m, debug: true);
      // responseList.forEach((element) {if(kDebugMode)print(element);});
      // List<Contact> l = responseList.map((data) => Contact.fromJson(data)).toList();
      // var db = await AppDatabase().addAddrBook(l);
      // if (db == 1) {
      //   return 1;
      // }
      // return 0;
      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      var jwt = await SecureStorage.read(key: globals.TOKEN);
      final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
        "Authorization": jwt!,
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
        return 0;
      }
    } on TimeoutException catch (_) {
      if(kDebugMode)print("Timeout");
      return 0;
    } catch (e) {
      if(kDebugMode)print(e);
      return 0;
    }
  }

  static Future<void> saveMessageGroup() async {
    try {
      String? addr = await SecureStorage.read(key: globals.ADR);
      String? timez = await SecureStorage.read(key: globals.LOCALE);
      Map<String, dynamic> m = {
        "param1": addr,
        "param2": timez,
        "request": "getMessageGroup",
      };
      ComInterface ci = ComInterface();
      List rt = await ci.get("/data", request: m, debug: true, type: ComInterface.typePlain);
      List<MessageGroup> list = rt.map((data) => MessageGroup.fromJson(data)).toList();
      // List<MessageGroup>? l = await compute(parseMessagesGroup, rt.body);
      await AppDatabase().addMessageGroup(list);
      // List<MessageGroup>? l = rt.map((data) => MessageGroup.fromJson(data)).toList();
      // await AppDatabase().addMessageGroup(l!);
      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));
      // if (response.statusCode == 200) {
      //   List<MessageGroup>? l = await compute(parseMessagesGroup, response.body);
      //   await AppDatabase().addMessageGroup(l!);
      // }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
    } catch (e) {
      if(kDebugMode)print(e.toString());
    }
  }

  // static List<MessageGroup>? parseMessagesGroup(String body) {
  //   try {
  //     var data = decryptAESCryptoJS(body.toString(), "rp9ww*jK8KX_!537e%Crmf");
  //     List responseList = json.decode(data);
  //
  //     return l;
  //   } catch (e) {
  //     if(kDebugMode)print(e);
  //     return null;
  //   }
  // }

  static Future<int> saveMessages(String address, int idMax) async {
    try {
      String? addr = await SecureStorage.read(key: globals.LOCALE);
      String? addr2 = await SecureStorage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "id": idMax,
        "param1": address,
        "param2": addr,
        "param3": addr2,
        "request": "getMessages",
      };

      ComInterface ci = ComInterface();
      List<dynamic> response = await ci.get("/data", request: m);
      List<Message> l = response.map((data) => Message.fromJson(data)).toList();
      int i = await AppDatabase().addMessages(l);
      return i;
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
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
      if(kDebugMode)print(e);
      return null;
    }
  }

  static Future<void> updateRead(String address) async {
    try {
      String? addr = await SecureStorage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "param1": address,
        "param2": addr,
        "request": "updateRead",
      };

      ComInterface ci = ComInterface();
      Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);

      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await AppDatabase().updateMessageGroupRead(addr!, address);
      }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
    } catch (e) {
      if(kDebugMode)print(e.toString());
    }
  }

  static Future<int> updateLikes(int id) async {
    try {
      String? addr = await SecureStorage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "id": id,
        "param": addr,
        "request": "updateLikes",
      };

      ComInterface ci = ComInterface();
      Map<dynamic, dynamic> response = await ci.get("/data", request: m);

      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

      // var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
      // Map m = json.decode(data);
      int i = int.parse(response['likes'].toString().trim());
      await AppDatabase().updateMessageLikes(id, i);
      return i;
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return 0;
    }
  }

  static Future<void> updateContact(String name, String id) async {
    try {
      Map<String, dynamic> m = {
        "param1": id,
        "param2": name,
        "request": "updateContact",
      };

      ComInterface ci = ComInterface();
      Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);
      if (response.statusCode == 200) {
        // AppDatabase().updateMessageGroupRead(addr, address);
      }
      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));
      // if (response.statusCode == 200) {
      //   // AppDatabase().updateMessageGroupRead(addr, address);
      // }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
    } catch (e) {
      if(kDebugMode)print(e.toString());
    }
  }

  static Future<void> sendMessage(String address, String text, int idReply) async {
    try {
      // String? jwt = await storage.read(key: "jwt");
      String? addr = await SecureStorage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "id": idReply,
        "param1": addr,
        "param2": address,
        "param3": text,
        "request": "sendMessage",
      };

      ComInterface ci = ComInterface();
      await ci.get("/data", request: m, type: ComInterface.typePlain);
      await AppDatabase().updateMessageGroupRead(addr!, address);
      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));
      // if (response.statusCode == 200) {
      //
      // }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
    } catch (e) {
      if(kDebugMode)print(e.toString());
    }
  }

  static Future<int> sendContactCoins(String amount, String name, String addr) async {
    try {
      String? id = await SecureStorage.read(key: globals.ID);
      String? user = await SecureStorage.read(key: globals.USERNAME);

      Map<String, dynamic> m = {
        "User": user,
        "id": id,
        "request": "sendContactTransaction",
        "param1": addr,
        "param2": amount,
        "param3": name,
      };

      ComInterface ci = ComInterface();
      Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);

      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return 1;
      } else {
        return 2;
      }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return 0;
    }
  }

  static Future<int> sendStakeCoins(String amount) async {
    try {
      String? id = await SecureStorage.read(key: globals.ID);
      String? user = await SecureStorage.read(key: globals.USERNAME);

      Map<String, dynamic> m = {
        "User": user,
        "id": id,
        "request": "setStake",
        "param1": amount,
      };

      ComInterface ci = ComInterface();
      Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);

      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

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
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return 0;
    }
  }

  static Future<int> unstakeCoins(int type) async {
    try {
      String? id = await SecureStorage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "id": id,
        "param1": type,
        "request": "unstake",
      };
      ComInterface ci = ComInterface();
      Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);

      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return 1;
      } else {
        return 2;
      }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return 0;
    }
  }

  static Future<Map<String, dynamic>?> getAdminNickname() async {
    String? id = await SecureStorage.read(key: globals.ID);
    Map<String, dynamic> m = {"id": id, "request": "getAdminNickname"};
    ComInterface ci = ComInterface();
    Map<String, dynamic> rt = await ci.get("/data", request: m, debug: true);
    return rt;
  }

  static Future<bool> checkPassword(String password) async {
    String? username = await SecureStorage.read(key: globals.USERNAME);
    try {
      Map<String, dynamic> m = {
        "username": username,
        "password": password,
      };

      ComInterface ci = ComInterface();
      Response res = await ci.get("/data", request: m, type: ComInterface.typePlain);
      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // var res = await http.post(Uri.parse("${globals.SERVER_URL}/login"), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return false;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return false;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return false;
    }
  }

  static Future<String?> getPrivKey() async {
    String? addr = await SecureStorage.read(key: globals.ADR);
    try {
      Map<String, dynamic> m = {"param1": addr, "request": "getPrivKey"};
      ComInterface ci = ComInterface();
      Response res = await ci.get("/data", request: m, type: ComInterface.typePlain);

      if (res.statusCode == 200) {
        String? data = decryptAESCryptoJS(res.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        return data;
      } else {
        return null;
      }
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return null;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return null;
    } catch (e) {
      if(kDebugMode)print(e.toString());
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
        String? id = await SecureStorage.read(key: globals.ID);

        Map<String, dynamic> m = {
          "id": id,
          "param1": nickname,
          "request": "renameUser",
        };
        ComInterface ci = ComInterface();
        Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);

        // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
        // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
        //   "Content-Type": "application/json",
        //   "payload": s,
        // }).timeout(const Duration(seconds: 10));

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
          await SecureStorage.write(key: globals.NICKNAME, value: map['nick']);
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
      String? id = await SecureStorage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "id": id,
        "param1": pass,
        "request": "changePassword",
      };
      ComInterface ci = ComInterface();
      Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);

      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (context.owner != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Your password has been changed!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            elevation: 5.0,
          ));
        }
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
    try {
      Map<String, dynamic> m = {
        "param1": addr,
        "request": "avatarVersion",
      };

      ComInterface ci = ComInterface();
      dynamic response = await ci.get("/data", request: m);
      return AppDatabase().insertUpdateAvatar(response['addr'], response['version']);
      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

      // if (response.statusCode == 200) {
      //   var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
      //   Map reponseMap = json.decode(data);
      //
      // }
      // return 0;
    } on TimeoutException catch (_) {
      if(kDebugMode)print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if(kDebugMode)print('No internet');
      return 0;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      return 0;
    }
  }

  static Future<String?> getRewardsByDay(BuildContext context, String date, int type) async {
    try {
      String? id = await SecureStorage.read(key: globals.ID);
      String? tz = await SecureStorage.read(key: globals.LOCALE);

      Map<String, dynamic> m = {
        "id": id,
        "param1": date,
        "param2": type,
        "param3": tz,
        "request": "getRewards",
      };

      ComInterface ci = ComInterface();
      List<dynamic> response = await ci.get("/data", request: m, debug: true);
      return response.toString();
      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

      // if (response.statusCode == 200) {
      //   var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
      //   if(kDebugMode)print(data.toString());
      //   return data.toString();
      // } else {
      //   Dialogs.openAlertBox(context, 'Warning', response.toString());
      //   return null;
      // }
    } on TimeoutException catch (_) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, 'Warning', "Request timed out");
      return null;
    } on SocketException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Service is not available");
      return null;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<String?> getRewardsByMonth(BuildContext context, String year, String month, int type) async {
    try {
      String? id = await SecureStorage.read(key: globals.ID);

      Map<String, dynamic> m = {
        "id": id,
        "param1": year,
        "param2": type,
        "param3": month,
        "request": "getRewards",
      };

      ComInterface ci = ComInterface();
      Response response = await ci.get("/data", request: m, type: ComInterface.typePlain);
      // var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
      //
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": s,
      // }).timeout(const Duration(seconds: 10));

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
      if(kDebugMode)print(e.toString());
      Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<Map?> getPoolStats(BuildContext context) async {
    try {
      String? id = await SecureStorage.read(key: globals.ID);

      Map<String, dynamic> m = {"id": id, "request": "getPoolStats"};

      ComInterface ci = ComInterface();
      Map response = await ci.get("/data", request: m);
      return response;
      // final response = await http.get(Uri.parse('${globals.SERVER_URL}/data'), headers: {
      //   "Content-Type": "application/json",
      //   "payload": encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf"),
      // }).timeout(const Duration(seconds: 10));

      // if (response.statusCode == 200) {
      //   var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
      //   Map reponseMap = json.decode(data);
      //   return reponseMap;
      // } else {
      //   // Dialogs.openAlertBox(context, 'Error', response.body.toString());
      //   return null;
      // }
    } on TimeoutException catch (_) {
      // Dialogs.openAlertBox(context, 'Error',
      //     "Request timed out, can't save the picture to cloud");
      return null;
    } on SocketException catch (_) {
      // Dialogs.openAlertBox(context, 'Error',
      //     "Service is not available, can't save the picture to cloud");
      return null;
    } catch (e) {
      if(kDebugMode)print(e.toString());
      // Dialogs.openAlertBox(context, 'Error', e.toString());
      return null;
    }
  }
}
