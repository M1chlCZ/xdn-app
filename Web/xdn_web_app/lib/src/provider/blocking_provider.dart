import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockProvider extends ChangeNotifier {
  bool _isBlocked = false;

  bool get isLoading => _isBlocked;

  void setBlock(bool isLoading) {
    _isBlocked = isLoading;
    notifyListeners();
  }
}

final blockProvider = ChangeNotifierProvider<BlockProvider>((ref) {
  return BlockProvider();
});