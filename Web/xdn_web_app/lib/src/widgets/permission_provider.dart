// user/permission

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/support/s_p.dart';

final permissionProvider = FutureProvider((ref) async {
  var net = ref.read(networkProvider);
  Map<String, dynamic> rt = await net.get("/user/permissions", serverType: ComInterface.serverGoAPI);
  return rt;
});