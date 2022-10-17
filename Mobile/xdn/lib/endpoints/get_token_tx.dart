
import 'package:digitalnote/models/TokenTx.dart';
import 'package:digitalnote/net_interface/interface.dart';

class TokenTxList {
  final ComInterface _interface = ComInterface();

  Future<TokenTx> getTokenData() async {
    Map<String, dynamic> m = {
      "timestamp": 0
    };
    var rs = await _interface.post("/user/token/tx", serverType: ComInterface.serverGoAPI, body: m);
    TokenTx st = TokenTx.fromJson(rs);
    return st;
  }
}