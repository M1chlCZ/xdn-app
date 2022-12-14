import 'dart:async';

import 'package:digitalnote/endpoints/get_masternode_graph.dart';
import 'package:digitalnote/generated/phone.pb.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:rxdart/rxdart.dart';

class MasternodeGraphBloc {
  final MasternodeList _coinsList = MasternodeList();
  MasternodeGraphResponse? _stakingData;
  int typeBack = 0;

  StreamController<ApiResponse<MasternodeGraphResponse>>? _coinListController;

  StreamSink<ApiResponse<MasternodeGraphResponse>> get coinsListSink =>
      _coinListController!.sink;

  Stream<ApiResponse<MasternodeGraphResponse>> get coinsListStream =>
      _coinListController!.stream;

  stakeBloc() {
    _coinListController = BehaviorSubject<ApiResponse<MasternodeGraphResponse>>();
  }

  fetchStakeData(int coinID, int type) async {

    try {
      if (typeBack != type) {
        _stakingData = null;
      }
      if (_stakingData == null) {
        typeBack = type;
        coinsListSink.add(ApiResponse.loading('Fetching All Stakes'));
        MasternodeGraphResponse? coins = await _coinsList.getMasternodeGraphData(coinID, type);
        coinsListSink.add(ApiResponse.completed(coins));
      }else{
        MasternodeGraphResponse? coins = await _coinsList.getMasternodeGraphData(coinID, type);
        coinsListSink.add(ApiResponse.completed(coins));
      }
    } catch (e) {
      coinsListSink.add(ApiResponse.error(e.toString()));
      //
    }
  }

  dispose() {
    _coinListController?.close();
  }
}