import 'package:digitalnote/models/Bugs.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bugProvider = StateNotifierProvider<BugProvider, AsyncValue<List<BugData>>>((ref) {
  final ComInterface n = ComInterface();
  return BugProvider(n);
});

class BugProvider extends StateNotifier<AsyncValue<List<BugData>>> {
  final ComInterface com;
  BugProvider(this.com) : super(const AsyncLoading());

  void getBugs() async {
    try {
      dynamic response = await com.get("/misc/bug/user", serverType: ComInterface.serverGoAPI, debug: true);
      var l = response['data'] as List;
      if (l.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      var list = l.map((item) => BugData.fromJson(item)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      print(e);
      state = AsyncValue.error(e, st);
    }
  }
}