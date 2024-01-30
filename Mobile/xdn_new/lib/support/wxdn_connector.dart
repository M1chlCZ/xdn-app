import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:digitalnote/support/wallet_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_qrcode_modal_dart/walletconnect_qrcode_modal_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  connectionFailed,
  connectionCancelled,
}
class WalletConnectEthereumCredentials extends CustomTransactionSender {
  WalletConnectEthereumCredentials({required this.provider});

  final EthereumWalletConnectProvider provider;



  @override
  Future<EthereumAddress> extractAddress() {
    // TODO: implement extractAddress
    throw UnimplementedError();
  }

  @override
  Future<String> sendTransaction(Transaction transaction) async {
    final hash = await provider.sendTransaction(
      from: transaction.from!.hex,
      to: transaction.to?.hex,
      data: transaction.data,
      gas: transaction.maxGas,
      gasPrice: transaction.gasPrice?.getInWei,
      value: transaction.value?.getInWei,
      nonce: transaction.nonce,
    );

    return hash;
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    throw UnimplementedError();
  }

  @override
  EthereumAddress get address => EthereumAddress.fromHex(provider.connector.session.accounts[0]);

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) {
    throw provider.sendRawTransaction(data: payload);
  }
}

class WXDConnector implements WalletConnector {
  String? abiFile;
  final EthereumAddress contractAddr =
  EthereumAddress.fromHex('0xbEA2576F400B070c7cDf11d1cBB49dE0C84e3bCF', enforceEip55: true);
  DeployedContract? contract;
  ContractFunction? sendFunction;
  EtherAmount? gas;
  WXDConnector() {
    _connector = WalletConnectQrCodeModal(
      connector: WalletConnect(
        clientId: "XDN",
        bridge: 'https://bridge.walletconnect.org',
        clientMeta: const PeerMeta(
          name: 'XDN app',
          description: 'Digitalnote',
          url: 'https://digitalnote.org',
          icons: [
            'https://github.com/DigitalNoteXDN/MediaPack/blob/master/XDN/DN2020_circle_hires.png?raw=true'
          ],
        ),
      ),
    );
// KonskejReper5@5
    _provider = EthereumWalletConnectProvider(_connector.connector);

  }

  @override
  Future<SessionStatus?> connect(BuildContext context) async {
    return await _connector.connect(context, chainId: 1);

  }

  @override
  void registerListeners(
      OnConnectRequest? onConnect,
      OnSessionUpdate? onSessionUpdate,
      OnDisconnect? onDisconnect,
      ) =>
      _connector.registerListeners(
        onConnect: onConnect,
        onSessionUpdate: onSessionUpdate,
        onDisconnect: onDisconnect,
      );

  @override
  Future<String?> sendTestingAmount({
    required String recipientAddress,
    required double amount,
  }) async {
    final sender =
    EthereumAddress.fromHex(_connector.connector.session.accounts[0]);
    final recipient = EthereumAddress.fromHex(recipientAddress, enforceEip55: true);
    debugPrint('sender: $sender');
    debugPrint('recipient: $recipient');

    final etherAmount = EtherAmount.fromUnitAndValue(
        EtherUnit.ether, amount.toInt());
    debugPrint('etherAmount: $etherAmount');

    // final transaction = Transaction(
    //   to: recipient,
    //   from: sender,
    //   gasPrice: EtherAmount.inWei(BigInt.one),
    //   maxGas: 100000,
    //   value: etherAmount,
    // );

    final tx = Transaction.callContract(contract: contract!,
      function: sendFunction!,
      parameters: [recipient, etherAmount.getInWei],
      from: sender,
        maxFeePerGas: EtherAmount.zero(),
        gasPrice: gas,
      // gasPrice: null,
      // value: etherAmount,
      // maxGas: 100000,
    );

    final credentials = WalletConnectEthereumCredentials(provider: _provider);

    // Sign the transaction
    try {
      final txBytes = await _ethereum.sendTransaction(credentials, tx, fetchChainIdFromNetworkId: true);
      return txBytes;
    } catch (e) {
      print('Error: $e');
    }

    // Kill the session
    // _connector.killSession();

    return null;
  }

  @override
  Future<void> openWalletApp() async => await _connector.openWalletApp();

  @override
  Future<Map<String, dynamic>?> getData() async {
    try {
      final abiCode = await rootBundle.loadString('assets/wxdn.json');
      // final abiCode = await abiFile!.readAsString();
      print('${abiCode.length}abi code length');
      contract =
          DeployedContract(ContractAbi.fromJson(abiCode, 'WXDN'), contractAddr);
      final address =
      EthereumAddress.fromHex(_connector.connector.session.accounts[0]);
      // debugPrint('${address} address');
      final amount = await _ethereum.getBalance(address);
      gas = await _ethereum.getGasPrice();
      final g = gas!.getInWei / BigInt.from(pow(10, 18));
      // debugPrint('bnb amount ${amount.getInWei / BigInt.from(pow(10, 18))} gas ${Decimal.parse(g.toString()).toString()}');
      // extracting some functions and events that we'll need later
      // final transferEvent = contract.event('Transfer');
      final balanceFunction = contract!.function('balanceOf');
      sendFunction = contract!.function("transfer");
      // final sendFunction = contract.function('sendCoin');
      final balance = await _ethereum.call(
          contract: contract!, function: balanceFunction, params: [address]);
      var dd = balance.first as BigInt;
      var the = EtherAmount.inWei(dd);
      // debugPrint('We have $dd 2XDN ////////// ');
      Map<String, dynamic> m = {
        "xdn" : the.getValueInUnit(EtherUnit.ether),
        "bnb" : amount.getInWei / BigInt.from(pow(10, 18)),
        "gas" : Decimal.parse(g.toString()).toString()
      };
      return m;
    } catch (e, t) {
      print(e);
      print(t);
      return null;
    }
  }

  @override
  bool validateAddress({required String address}) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String get faucetUrl => 'https://faucet.dimensions.network/';


  @override
  String get address => _connector.connector.session.accounts[0];

  @override
  String get coinName => '2XDN';

  late final WalletConnectQrCodeModal _connector;
  late final EthereumWalletConnectProvider _provider;
  final _ethereum = Web3Client(
      'https://greatest-flashy-silence.bsc.discover.quiknode.pro/780e1c3203b78046ad73e463c8ab9ae218a743b8/',
      Client());
}