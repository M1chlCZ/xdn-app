
import 'package:digitalnote/models/staking_data.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:intl/intl.dart';

class StakeList {
  final ComInterface _interface = ComInterface();

  Future<StakingData> getStakingData(int type) async {
    Map<String, dynamic> m = {
      "type": type,
      "datetime": type == 1 ? DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()) : Utils.getUTC()
    };
    var rs = await _interface.post("/staking/graph", serverType: ComInterface.serverGoAPI, body: m);
    StakingData st = StakingData.fromJson(rs);
    return st;
  }
}