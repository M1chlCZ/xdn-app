import 'dart:async';

import 'package:digitalnote/endpoints/get_stealth_tx.dart';
import 'package:digitalnote/models/StealthTX.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class StealthTxBloc {
  final StealthTxList _coinsList = StealthTxList();
  StealthTX? _stakingData;
  int typeBack = 0;

  StreamController<ApiResponse<StealthTX>>? _coinListController;

  StreamSink<ApiResponse<StealthTX>> get coinsListSink =>
      _coinListController!.sink;

  Stream<ApiResponse<StealthTX>> get coinsListStream =>
      _coinListController!.stream;

  StealthTxBloc() {
    _coinListController = BehaviorSubject<ApiResponse<StealthTX>>();
  }

  fetchTokenData() async {
    try {
      if (_stakingData == null) {
        coinsListSink.add(ApiResponse.loading('Fetching All Stakes'));
        _stakingData = await _coinsList.getTokenData();
        coinsListSink.add(ApiResponse.completed(_stakingData));
      } else {
        _stakingData = await _coinsList.getTokenData();
        coinsListSink.add(ApiResponse.completed(_stakingData));
      }
    } catch (e) {
      coinsListSink.add(ApiResponse.error(e.toString()));
      // print(e);
    }
  }

  dispose() {
    _coinListController?.close();
  }
}