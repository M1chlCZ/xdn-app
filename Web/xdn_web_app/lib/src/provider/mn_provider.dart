import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MNProvider extends ChangeNotifier {
  String? _mnConf;
  String? _tx;

  String? get getMNConf => _mnConf;
  String? get getTx => _tx;

  void setConfig(String? mnConf) {
    _mnConf = mnConf;
    notifyListeners();
  }

  void setTxId(String? txId) {
    _tx = txId;
    notifyListeners();
  }
}

final mnProvider = ChangeNotifierProvider<MNProvider>((ref) {
  return MNProvider();
});