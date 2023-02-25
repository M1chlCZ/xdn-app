import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/models/Transactions.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';

final transactionProvider = StateNotifierProvider<RequestProvider, AsyncValue<List<TranSaction?>>>((ref) {
  final ComInterface n = ComInterface();
  return RequestProvider(n);
});

class RequestProvider extends StateNotifier<AsyncValue<List<TranSaction?>>> {
  final ComInterface com;

  RequestProvider(this.com) : super(const AsyncLoading());

  Future<void> getRequest() async {
    try {
      var response = await _getTranData();
      state = AsyncValue.data(response);
    } catch (e) {
      print(e);
      state = const AsyncValue.data([]);
    }
  }
}

Future<List<TranSaction?>> _getTranData() async {
  try {
    ComInterface ci = ComInterface();
    Map<String, dynamic>? res = await ci.get("/user/transactions", serverType: ComInterface.serverGoAPI, debug: false);
    List<dynamic> rt = res!['data'];
    var i = rt.map((element) => TranSaction.fromJson(element)).toList();
    return i;
  } catch (e) {
    print(e);
    return [];
  }
}
