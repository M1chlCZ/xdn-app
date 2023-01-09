import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xdn_web_app/src/models/MNList.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/support/s_p.dart';

final itemsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    dynamic response = await ref.read(networkProvider).get("/masternode/non/list", serverType: ComInterface.serverGoAPI, debug: true );
    if (response["data"] == null) {
      List<dynamic> lret = [];
      lret.add("end");
      return lret;
    }
    var l = response['data'] as List;
    var list = l.map((item) => MNList.fromJson(item)).toList();
    List<dynamic> lret = [];
    lret.addAll(list);
    lret.add("end");
    return lret;
  } catch (e) {
    print(e);
    return [];
  }
});