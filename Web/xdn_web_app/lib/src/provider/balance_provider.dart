import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/support/s_p.dart';

final balanceProvider = FutureProvider((ref) async {
  var net = ref.read(networkProvider);
  Map<String, dynamic> rt = await net.get("/user/balance", serverType: ComInterface.serverGoAPI);
  return rt;
});