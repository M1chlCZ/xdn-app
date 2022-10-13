import 'dart:async';

import 'package:digitalnote/endpoints/get_stake_graph.dart';
import 'package:digitalnote/models/staking_data.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class StakeGraphBloc {
  final StakeList _coinsList = StakeList();
  StakingData? _stakingData;
  int typeBack = 0;

  StreamController<ApiResponse<StakingData>>? _coinListController;

  StreamSink<ApiResponse<StakingData>> get coinsListSink =>
      _coinListController!.sink;

  Stream<ApiResponse<StakingData>> get coinsListStream =>
      _coinListController!.stream;

  stakeBloc() {
    _coinListController = BehaviorSubject<ApiResponse<StakingData>>();
  }

  fetchStakeData(int type) async {
    try {
      if (typeBack != type) {
        _stakingData = null;
      }
      typeBack = type;
      if (_stakingData == null) {
        coinsListSink.add(ApiResponse.loading('Fetching All Stakes'));
        _stakingData = await _coinsList.getStakingData(type);
        coinsListSink.add(ApiResponse.completed(_stakingData));
      } else {
        _stakingData = await _coinsList.getStakingData(type);
        coinsListSink.add(ApiResponse.completed(_stakingData));
      }
      // _stakingData = await _coinsList.getStakingData(type);
      // coinsListSink.add(ApiResponse.completed(_stakingData));
    } catch (e) {
      coinsListSink.add(ApiResponse.error(e.toString()));
      // print(e);
    }
  }

  dispose() {
    _coinListController?.close();
  }
}