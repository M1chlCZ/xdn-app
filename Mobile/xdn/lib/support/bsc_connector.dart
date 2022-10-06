import 'dart:math';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:digitalnote/support/wallet_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_qrcode_modal_dart/walletconnect_qrcode_modal_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

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
    // TODO: implement signToSignature
    throw UnimplementedError();
  }
}

class BSCConnector implements WalletConnector {
  String? abiFile;
  final EthereumAddress contractAddr =
  EthereumAddress.fromHex('0xC14527D6E8BdFbE2c57c41Bd6014b80639cde364', enforceEip55: true);
  DeployedContract? contract;
  ContractFunction? sendFunction;
  EtherAmount? gas;
  BSCConnector() {
    _connector = WalletConnectQrCodeModal(
      connector: WalletConnect(
        bridge: 'https://bridge.walletconnect.org',
        clientMeta: const PeerMeta(
          name: 'XDN app',
          description: 'Digitalnote Development Voting',
          url: 'https://digitalnote.org',
          icons: [
            'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
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

    final etherAmount = EtherAmount.fromUnitAndValue(
        EtherUnit.ether, amount.toInt());

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


  // Future<double> getBalance() async {
  //
  //   final address =
  //   EthereumAddress.fromHex(_connector.connector.session.accounts[0]);
  //   final amount = await _ethereum.getBalance(address);
  //   return amount.getValueInUnit(EtherUnit.ether).toDouble();
  // }
  @override
  Future<double> getBalance() async {
    try {
      final abiCode = await rootBundle.loadString('assets/abi.json');
      // final abiCode = await abiFile!.readAsString();
      print('${abiCode.length}abi code length');
      contract =
          DeployedContract(ContractAbi.fromJson(abiCode, '2XDN'), contractAddr);
      final address =
      EthereumAddress.fromHex(_connector.connector.session.accounts[0]);
      print('${address} address');
      final amount = await _ethereum.getBalance(address);
      gas = await _ethereum.getGasPrice();
      final g = gas!.getInWei / BigInt.from(pow(10, 18));
      print('bnb amount ${amount.getInWei / BigInt.from(pow(10, 18))} gas ${Decimal.parse(g.toString()).toString()}');
      // extracting some functions and events that we'll need later
      // final transferEvent = contract.event('Transfer');
      final balanceFunction = contract!.function('balanceOf');
      sendFunction = contract!.function("transfer");
      // final sendFunction = contract.function('sendCoin');
      final balance = await _ethereum.call(
          contract: contract!, function: balanceFunction, params: [address]);
      var dd = balance.first as BigInt;
      var the = EtherAmount.inWei(dd);
      print('We have $dd MetaCoins ////////// ');
      return the.getInEther.toDouble();
    } catch (e, t) {
      print(e);
      print(t);
      return 0.0;
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