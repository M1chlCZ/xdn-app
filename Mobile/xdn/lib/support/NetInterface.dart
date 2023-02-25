import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:digitalnote/models/StealhBalance.dart';
import 'package:digitalnote/net_interface/app_exception.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

import '../globals.dart' as globals;
import 'AppDatabase.dart';
import '../models/Contact.dart';
import 'Dialogs.dart';
import '../models/Message.dart';
import '../models/MessageGroup.dart';
import '../models/TranSaction.dart';

class NetInterface {
  static void uploadPicture(BuildContext context, String base64) async {
    try {
      ComInterface interface = ComInterface();
      Response response = await interface.post("/avatar/upload",
          body: {"file": base64}, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);

      if (response.statusCode == 200) {
      } else {
        // Dialogs.openAlertBox(context, 'Warning', response.toString());
      }
    } on TimeoutException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Request timed out, can't save the picture to cloud");
    } on SocketException catch (_) {
      Dialogs.openAlertBox(context, 'Warning', "Service is not available, can't save the picture to cloud");
    } catch (e) {
      if (kDebugMode) print(e.toString());
      Dialogs.openAlertBox(context, 'Warning', e.toString());
    }
  }

  static Future<Uint8List?> downloadCSV(BuildContext context) async {
    try {
      ComInterface interface = ComInterface();
      Response response = await interface.get("/user/xls",
          body: {}, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return base64.decode(data['data']);
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
      if (kDebugMode) print(e.toString());
      Dialogs.openAlertBox(context, 'Error', e.toString());
      return null;
    }
  }

  static Future<String?> dowloadPicture(BuildContext context, int? userID) async {
    try {
      ComInterface interface = ComInterface();
      Response response = await interface.post("/avatar",
          body: {"id": userID ?? 0}, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain);

      if (response.statusCode == 200) {
        var s = json.decode(response.body);
        return s['avatar'];
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
      if (kDebugMode) print(e.toString());
      // Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<String?> dowloadPictureByAddr(String addr) async {
    try {
      ComInterface interface = ComInterface();
      Response response = await interface.post("/avatar",
          body: {"address": addr}, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);
      if (response.statusCode == 200) {
        var s = json.decode(response.body);
        return s['avatar'];
      } else {
        if (kDebugMode) print("sucks");
        // Dialogs.openAlertBox(context, 'Warning', response.toString());
        return null;
      }
    } catch (e) {
      if (kDebugMode) print(e.toString());
      // Dialogs.openAlertBox(context, 'Warning', e.toString());
      return null;
    }
  }

  static Future<void> registerFirebaseToken(String? token) async {
    if (token == null) return;
    ComInterface interface = ComInterface();
    try {
    await interface.post("/firebase",
        body: {"token": token, "platform": Platform.isAndroid ? "A" : "I"}, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  static Future<int> getTranData() async {
    try {
      ComInterface ci = ComInterface();
      Map<String, dynamic>? res = await ci.get("/user/transactions", serverType: ComInterface.serverGoAPI, debug: false);
      List<dynamic> rt = res!['data'];
      var l = await compute(getTransactionCompute, rt);
      var i = await AppDatabase().addTransactions(l);
      return i;
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return 0;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return 0;
    }
  }

  static List<TranSaction> getTransactionCompute(List<dynamic> response) {
    List<TranSaction> l = response.map((data) => TranSaction.fromJson(data)).toList();
    return l;
  }

  static Future<Map<String, dynamic>>? getBalance({bool details = false}) async {
       ComInterface ci = ComInterface();
    Map<String, dynamic> rt = await ci.get("/user/balance", serverType: ComInterface.serverGoAPI);
    return rt;
  }

  static Future<Map<String, dynamic>>? getTokenBalance() async {
      ComInterface ci = ComInterface();
    Map<String, dynamic> rt = await ci.get("/user/token/wxdn", serverType: ComInterface.serverGoAPI, debug: false);
    return rt;
  }

  static Future<StealthBalance?> getStealthBalance() async {
    try {
      ComInterface ci = ComInterface();
      Map<String, dynamic> rt = await ci.get("/user/stealth/balance", serverType: ComInterface.serverGoAPI, debug: false);
      return StealthBalance.fromJson(rt);
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<Map<String, dynamic>>? getPriceData({bool details = false}) async {
    ComInterface ci = ComInterface();
    Map<String, dynamic> res = await ci.get("/price/data", request: {}, serverType: ComInterface.serverGoAPI, debug: true);
    return res['data'];
  }

  static Future<int> getAddrBook() async {
    try {
      ComInterface ci = ComInterface();
      Map<String, dynamic> rt = await ci.get("/user/addressbook", request: {}, serverType: ComInterface.serverGoAPI);
      List<dynamic> lst = rt['data'];
      if (lst.isNotEmpty) {
        List<Contact> l = lst.map((l) => Contact.fromJson(l)).toList();
        AppDatabase().addAddrBook(l);
        return 1;
      }
      return 0;
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return 0;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return 0;
    }
  }

  static Future<int> saveContact(String name, String addr, BuildContext context) async {
    if (name.isEmpty) {
      Dialogs.openAlertBox(context, "Error", "Name cannot be empty");
      return 0;
    }
    try {
      Map<String, dynamic> m = {
        "name": name,
        "addr": addr,
      };

      ComInterface ci = ComInterface();
      Response response = await ci.post("/user/addressbook/save", body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain);
      if (response.statusCode == 200) {
        Map<String, dynamic > responseList = json.decode(response.body);
        List<dynamic> lst = responseList['data'];
        List<Contact> l = lst.map((data) => Contact.fromJson(data)).toList();
        var db = await AppDatabase().addAddrBook(l);
        if (db == 1) {
          return 1;
        }
        return 0;
      } else {
        return 0;
      }
    } on TimeoutException catch (_) {
      if (kDebugMode) print("Timeout");
      return 0;
    } catch (e) {
      if (kDebugMode) print(e);
      return 0;
    }
  }

  static Future<void> saveMessageGroup() async {
    try {
      ComInterface ci = ComInterface();
      Map <String, dynamic> res = await ci.get("/user/messages/group", request: {}, serverType: ComInterface.serverGoAPI, debug: false);
      List rt = res['data'];
      List<MessageGroup> list = rt.map((data) => MessageGroup.fromJson(data)).toList();
      await AppDatabase().addMessageGroup(list);
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }


  static Future<int> saveMessages(String address, int idMax) async {
    try {
      var d = DateTime.fromMillisecondsSinceEpoch(idMax * 1000).toUtc();
      Map<String, dynamic> m = {
        "addr": address,
        "last_sync": d.toIso8601String(),
      };
      ComInterface ci = ComInterface();
      Map<String, dynamic> res = await ci.post("/user/messages",
          body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
      List<dynamic> response = res["data"];
      List<Message> l = response.map((data) => Message.fromJson(data)).toList();
      int i = await AppDatabase().addMessages(l);
      return i;
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return 0;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return 0;
    }
  }

  // static List<Message>? parseMessages(String body) {
  //   try {
  //     var data = decryptAESCryptoJS(body.toString(), "rp9ww*jK8KX_!537e%Crmf");
  //     List responseList = json.decode(data);
  //     List<Message> l = responseList.map((data) => Message.fromJson(data)).toList();
  //     return l;
  //   } catch (e) {
  //     if (kDebugMode) print(e);
  //     return null;
  //   }
  // }

  static Future<void> updateRead(String address) async {
    try {
      String? addr = await SecureStorage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "addr": address,
        "addrUsr": addr,
      };
      ComInterface ci = ComInterface();
      Response response = await ci.post("/user/messages/read", body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);
      if (response.statusCode == 200) {
        await AppDatabase().updateMessageGroupRead(addr!, address);
      }
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  static Future<int> updateLikes(int id) async {
    try {
      String? addr = await SecureStorage.read(key: globals.ADR);

      Map<String, dynamic> m = {
        "id": id,
        "addr": addr,
      };

      ComInterface ci = ComInterface();
      Map<String, dynamic> res = await ci.post("/user/messages/likes",
          body:m, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);

      int i = int.parse(res['likes'].toString().trim());
      await AppDatabase().updateMessageLikes(id, i);
      return i;
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return 0;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return 0;
    }
  }

  static Future<void> updateContact(String name, String id) async {
    try {
      Map<String, dynamic> m = {
        "id": id,
        "name": name,
      };

      ComInterface ci = ComInterface();
      Response response = await ci.get("/addressbook/update", body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain);
      if (response.statusCode == 200) {
        // AppDatabase().updateMessageGroupRead(addr, address);
      }

    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  static Future<void> sendMessage(String address, String text, int idReply) async {
    try {
      String? addr = await SecureStorage.read(key: globals.ADR);
      Map<String, dynamic> m = {
        "idReply": idReply,
        "addr": address,
        "text": text,
      };
      ComInterface ci = ComInterface();
      await ci.post("/user/messages/send", body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);
      await AppDatabase().updateMessageGroupRead(addr!, address);

    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  static Future<int> sendContactCoins(String amount, String name, String addr) async {
    try {

      ComInterface interface = ComInterface();
      Response response = await interface.post("/user/send/contact",
          body: {"address": addr, "contact": name, "amount": double.parse(amount)}, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);

      if (response.statusCode == 200) {
        return 1;
      } else {
        return 2;
      }
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return 0;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return 0;
    }
  }


  static Future<dynamic> checkPassword(String password, {String? pin}) async {
    String? username = await SecureStorage.read(key: globals.USERNAME);
    try {
        Map<String, dynamic> m = {
          "username": username,
          "password": password,
        };
        if (pin != null) {
          m['twoFactor'] = pin;
        }

        ComInterface ci = ComInterface();
        Response res = await ci.post("/login", body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);

      if (res.statusCode == 200) {
        return true;
      } else if (res.statusCode == 409) {
        return "fa";
      } else {
        return false;
      }
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return false;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return false;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    }
  }

  static Future<String?> getPrivKey() async {
    try {
      ComInterface ci = ComInterface();
      var res = await ci.get("/misc/privkey", request: {}, type: ComInterface.typeJson, serverType: ComInterface.serverGoAPI, debug: false);
      return res['privkey'];
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return null;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return null;
    } catch (e) {
      if (kDebugMode) print(e.toString());
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
        Map<String, dynamic> m = {
          "name": nickname,
        };
        ComInterface ci = ComInterface();
        var response = await ci.post("/user/rename", body: m, type: ComInterface.typePlain, serverType: ComInterface.serverGoAPI, debug: false);
        if (response.statusCode == 200) {
          globals.reloadData = true;

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Your nickname has been changed!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            elevation: 5.0,
          ));

          await SecureStorage.write(key: globals.NICKNAME, value: nickname);
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
      Map<String, dynamic> m = {
        "password": pass,
      };

      ComInterface ci = ComInterface();
      Response response = await ci.post("/password/change", body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typePlain, debug: false);


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
      ComInterface ci = ComInterface();
      Map<String, dynamic> response = await ci.post("/avatar/version", body: {"address" : addr!}, serverType: ComInterface.serverGoAPI);
      return AppDatabase().insertUpdateAvatar(addr, response['version']);
    } on TimeoutException catch (_) {
      if (kDebugMode) print('Service unreachable');
      return 0;
    } on SocketException catch (_) {
      if (kDebugMode) print('No internet');
      return 0;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return 0;
    }
  }


  static Future<String?> getRewardsByDayDao(BuildContext context, int type) async {
    try {
      ComInterface interface = ComInterface();
      Map<String, dynamic> m = {
        "type": type,
        "datetime": type == 1 ? DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()) : Utils.getUTC()
      };

      String? rs = await interface.post("/staking/graph", debug: false, type: ComInterface.typePlain,
          serverType: ComInterface.serverDAO, body: m);
      return rs;
    }catch(e){
      return null;
    }
  }


  static Future<Map?> deleteAccount() async {
    try {
      ComInterface ci = ComInterface();
      await ci.post("/user/delete", body: {}, type: ComInterface.typeJson, serverType: ComInterface.serverGoAPI, debug: false);
      return {"status": "ok"};
    } on TimeoutException catch (_) {
      return null;
    } on SocketException catch (_) {
      return null;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return null;
    }
  }

  static Future<bool> daoLogin() async {
    try {
      ComInterface ci = ComInterface();
    Response r =  await ci.get("/ping", debug: false, serverType: ComInterface.serverDAO, type: ComInterface.typePlain, request: {});
    if (r.statusCode == 200) {
      return true;
    }else{
      return false;
    }
    }on UnauthorisedException catch (e) {
      if (kDebugMode) print(e.toString());
      var b = daoRegister();
      debugPrint("| Dao Register success : ${b.toString().toUpperCase()} |");
      return b;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    }
  }

  static Future<bool> checkContest() async {
    try {
      ComInterface ci = ComInterface();
      await ci.get("/contest/check", debug: false, serverType: ComInterface.serverDAO, request: {});
      return true;
    }on UnauthorisedException catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    }
  }

  static Future<bool> daoRegister() async {
    try {
      String? jwt = await SecureStorage.read(key: globals.TOKEN);
      ComInterface ci = ComInterface();
      Map response = await ci.post("/login", debug: false, serverType: ComInterface.serverDAO, body: {"token": jwt}, request: {});
      if(response["token"] != null) {
        var token = response["token"];
        debugPrint("| Dao Register success : ${token.toString()} |");
        SecureStorage.write(key: globals.TOKEN_DAO, value: token);
        return true;
      }else{
        return false;
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    } on SocketException catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    }on UnauthorisedException catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return false;
    }
  }
}
