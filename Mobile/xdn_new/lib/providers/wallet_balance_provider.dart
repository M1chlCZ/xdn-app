

import 'package:digitalnote/net_interface/interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allBalanceProvider = FutureProvider((ref) async {
  ComInterface ci = ComInterface();
  Map<String, dynamic> rt = await ci.get("/misc/admin/wallet", serverType: ComInterface.serverGoAPI);
  return rt;
});