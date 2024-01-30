import 'package:digitalnote/models/BugsAdmin.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bugAdminProvider = StateNotifierProvider<BugAdminProvider, AsyncValue<List<BugAdminData>>>((ref) {
  final ComInterface n = ComInterface();
  return BugAdminProvider(n);
});

class BugAdminProvider extends StateNotifier<AsyncValue<List<BugAdminData>>> {
  final ComInterface com;
  BugAdminProvider(this.com) : super(const AsyncLoading());

  void getBugs() async {
    try {
      dynamic response = await com.get("/misc/bug/admin", serverType: ComInterface.serverGoAPI, debug: true);
      var l = response['data'] as List;
      if (l.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      var list = l.map((item) => BugAdminData.fromJson(item)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      print(e);
      state = AsyncValue.error(e, st);
    }
  }
}