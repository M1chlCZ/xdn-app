import 'package:digitalnote/generated/phone.pbgrpc.dart';
import 'package:digitalnote/globals.dart' as globals;
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:intl/intl.dart';

class MasternodeList {
  Future<MasternodeGraphResponse?> getMasternodeGraphData(int coinID, int type) async {
    final channel = ClientChannel('194.60.201.213', port: 6805, options: const ChannelOptions(credentials: ChannelCredentials.insecure()));
    final stub = AppServiceClient(channel);

    try {
      String? token = await SecureStorage.read(key: globals.TOKEN_DAO);
      var response = await stub.masternodeGraph(
          MasternodeGraphRequest(
            idCoin: coinID,
            type: type,
            datetime: type == 1 ? DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()) : Utils.getUTC(),
          ),
          options: CallOptions(metadata: {'authorization': token ?? ""}));
      await channel.shutdown();
      return response;
    } catch (e) {
      debugPrint('Caught error: ${e.toString()}');
      return null;
    }
  }
}
