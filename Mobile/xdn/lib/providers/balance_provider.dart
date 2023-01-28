import 'package:digitalnote/support/NetInterface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final balanceProvider = FutureProvider((ref) async {
  final response = await NetInterface.getBalance(details: true);
  return response;
});

final balanceTokenProvider = FutureProvider((ref) async {
  final response = await NetInterface.getTokenBalance();
  return response;
});

final balanceStealthProvider = FutureProvider((ref) async {
  final response = await NetInterface.getStealthBalance();
  return response;
});

final priceDataProvider = FutureProvider((ref) async {
  final response = await NetInterface.getPriceData();
  return response;
});

