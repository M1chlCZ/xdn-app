import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/TranSaction.dart';

class TransactionEndpoint {

  Future<List<TranSaction>?> fetchDBTransactions() async {
    return AppDatabase().getTransactions();
  }

  Future<int> fetchNetTransactions() async {
   var i = await NetInterface.getTranData();
   return i;
  }

}