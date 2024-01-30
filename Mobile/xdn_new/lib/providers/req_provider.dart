import 'package:digitalnote/models/Req.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final requestProvider = StateNotifierProvider<RequestProvider, AsyncValue<List<Requests>>>((ref) {
  final ComInterface n = ComInterface();
  return RequestProvider(n);
});

class RequestProvider extends StateNotifier<AsyncValue<List<Requests>>> {
  final ComInterface com;
  RequestProvider(this.com) : super(const AsyncLoading());

  void getRequest() async {
    try {
      dynamic response = await com.get("/request/withdraw", serverType: ComInterface.serverGoAPI, debug: false);
      var l = response['requests'] as List;
      if (l.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      var list = l.map((item) => Requests.fromJson(item)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      print(e);
      state = AsyncValue.error(e, st);
    }
  }
}