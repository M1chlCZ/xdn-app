import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/TranSaction.dart';

class TransactionEndpoint {

  Future<List<TranSaction>?> fetchDBTransactions() async {
    await NetInterface.getTranData();
    return AppDatabase().getTransactions();
  }

}