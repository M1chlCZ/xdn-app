import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/globals.dart' as globals;

class MessagesEndpoint {
  Future<List<dynamic>?> getMessages(String addrOG) async {
    var addr = await SecureStorage.read(key: globals.ADR);
    var s = await AppDatabase().getMessages(addr!, addrOG);
    return s;
  }

  Future<int> refreshMessages(String addrOG) async {
    var addr = await SecureStorage.read(key: globals.ADR);
    int idMax = await AppDatabase().getMessageGroupMaxID(addr, addrOG);
    var i = await NetInterface.saveMessages(addrOG, idMax);
    return i;
  }
}