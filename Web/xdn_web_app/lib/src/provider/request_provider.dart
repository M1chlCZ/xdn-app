import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/models/WithReq.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/support/s_p.dart';

// final requestProvider = FutureProvider<List<WithReq>>((ref) async {
//   try {
//     dynamic response = await ref.read(networkProvider).get("/request/withdraw", serverType: ComInterface.serverGoAPI, debug: true );
//     var l = response['requests'] as List;
//     var list = l.map((item) => WithReq.fromJson(item)).toList();
//     return list;
//   } catch (e) {
//     print(e);
//     return [];
//   }
// });

final requestProvider = StateNotifierProvider<RequestProvider, AsyncValue<List<WithReq>>>((ref) {
  var n = ref.read(networkProvider);
  return RequestProvider(n);
});

class RequestProvider extends StateNotifier<AsyncValue<List<WithReq>>> {
final ComInterface com;
  RequestProvider(this.com) : super(const AsyncLoading());

void getRequest() async {
  try {
    dynamic response = await com.get("/request/withdraw", serverType: ComInterface.serverGoAPI, debug: true);
    var l = response['requests'] as List;
    var list = l.map((item) => WithReq.fromJson(item)).toList();
    state = AsyncValue.data(list);
  } catch (e) {
    print(e);
    state = const AsyncValue.data([]);
  }
}
}