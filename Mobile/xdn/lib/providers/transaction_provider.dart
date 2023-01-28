import 'package:digitalnote/models/TranSaction.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/AppDatabase.dart';

final transactionProvider = StateNotifierProvider<RequestProvider, AsyncValue<List<TranSaction?>>>((ref) {
  final ComInterface n = ComInterface();
  return RequestProvider(n);
});

class RequestProvider extends StateNotifier<AsyncValue<List<TranSaction?>>> {
  final ComInterface com;
  RequestProvider(this.com) : super(const AsyncLoading());

  Future<void> getRequest() async {
    try {
      dynamic response = await AppDatabase().getTransactions();
      state = AsyncValue.data(response);
      var i = await NetInterface.getTranData();
      if (i > 0) {
        response = await AppDatabase().getTransactions();
        state = AsyncValue.data(response);
      }
    } catch (e) {
      print(e);
      state = const AsyncValue.data([]);
    }
  }
}