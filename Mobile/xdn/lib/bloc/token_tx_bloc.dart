import 'dart:async';

import 'package:digitalnote/endpoints/get_stake_graph.dart';
import 'package:digitalnote/endpoints/get_token_tx.dart';
import 'package:digitalnote/models/TokenTx.dart';
import 'package:digitalnote/models/staking_data.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class TokenTxBloc {
  final TokenTxList _coinsList = TokenTxList();
  TokenTx? _stakingData;
  int typeBack = 0;

  StreamController<ApiResponse<TokenTx>>? _coinListController;

  StreamSink<ApiResponse<TokenTx>> get coinsListSink =>
      _coinListController!.sink;

  Stream<ApiResponse<TokenTx>> get coinsListStream =>
      _coinListController!.stream;

  TokenTxBloc() {
    _coinListController = BehaviorSubject<ApiResponse<TokenTx>>();
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