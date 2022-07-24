import 'dart:async';

import 'package:digitalnote/endpoints/get_transactions.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/support/TranSaction.dart';
import 'package:flutter/foundation.dart';

class TransactionBloc {
  final TransactionEndpoint _balanceList = TransactionEndpoint();
  List<TranSaction>? _coins;

  StreamController<ApiResponse<List<TranSaction>>>? _coinListController;

  StreamSink<ApiResponse<List<TranSaction>>> get coinsListSink => _coinListController!.sink;

  Stream<ApiResponse<List<TranSaction>>> get coinsListStream => _coinListController!.stream;

  TransactionBloc() {
    _coinListController = StreamController<ApiResponse<List<TranSaction>>>();
    // fetchTransactions();
  }

  showWait() async {
    coinsListSink.add(ApiResponse.loading('Fetching All Coins'));
  }

  fetchTransactions() async {
    try {
      coinsListSink.add(ApiResponse.loading('Fetching All Coins'));
      _coins = await _balanceList.fetchDBTransactions();
      coinsListSink.add(ApiResponse.completed(_coins));
      var i = await _balanceList.fetchNetTransactions();
      if(i > 0) {
        coinsListSink.add(ApiResponse.loading('Fetching All Coins'));
        _coins = await _balanceList.fetchDBTransactions();
        coinsListSink.add(ApiResponse.completed(_coins));
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!_coinListController!.isClosed) {
        coinsListSink.add(ApiResponse.error(e.toString()));
      }
      // print(e);
    }
  }

  dispose() {
    _coinListController?.close();
  }
}
