
import 'package:digitalnote/models/StealthTX.dart';
import 'package:digitalnote/net_interface/interface.dart';

class StealthTxList {
  final ComInterface _interface = ComInterface();

  Future<StealthTX> getTokenData() async {
    var rs = await _interface.get("/user/stealth/tx", serverType: ComInterface.serverGoAPI, debug: true);
    StealthTX st = StealthTX.fromJson(rs);
    return st;
  }
}