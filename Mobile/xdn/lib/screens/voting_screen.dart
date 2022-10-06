import 'dart:io';

import 'package:digitalnote/models/Contest.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/bsc_connector.dart';
import 'package:digitalnote/support/wallet_connector.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/data_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart' show join, dirname;

import '../widgets/backgroundWidget.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  connectionFailed,
  connectionCancelled,
}

class VotingScreen extends StatefulWidget {
  static const String route = "menu/voting";

  const VotingScreen({Key? key}) : super(key: key);

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  ComInterface interface = ComInterface();
  WalletConnector connector = BSCConnector();
  String nullDate = "1970-00-01 00:00:01";

  static const _networks = ['BNB)'];

  ConnectionState _state = ConnectionState.disconnected;
  String? _networkName = _networks.first;

  @override
  void initState() {
    super.initState();
    initConnector();
  }

  initConnector() {
    connector.registerListeners(
        // connected
        (session) => print('Connected: $session'),
        // session updated
        (response) => print('Session updated: $response'),
        // disconnected
        () {
      setState(() => _state = ConnectionState.disconnected);
      print('Disconnected');
    });
    try {
      var abiFile = File(join(dirname(Platform.script.path), 'abi.json'));
      print(abiFile.path);
    } catch (e) {
      print(e);
    }
  }

  String _transactionStateToString({required ConnectionState state}) {
    switch (state) {
      case ConnectionState.disconnected:
        return 'Connect!';
      case ConnectionState.connecting:
        return 'Connecting';
      case ConnectionState.connected:
        return 'Session connected';
      case ConnectionState.connectionFailed:
        return 'Connection failed';
      case ConnectionState.connectionCancelled:
        return 'Connection cancelled';
    }
  }

  void _openWalletPage() {
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => WalletPage(connector: connector),
    //   ),
    // );
  }

  VoidCallback? _transactionStateToAction(BuildContext context, {required ConnectionState state}) {
    print('State: ${_transactionStateToString(state: state)}');
    switch (state) {
      // Progress, action disabled
      case ConnectionState.connecting:
        return null;
      case ConnectionState.connected:
        // Open new page
        return () => _openWalletPage();

      // Initiate the connection
      case ConnectionState.disconnected:
      case ConnectionState.connectionCancelled:
      case ConnectionState.connectionFailed:
        return () async {
          setState(() => _state = ConnectionState.connecting);
          try {
            final session = await connector.connect(context);
            if (session != null) {
              setState(() => _state = ConnectionState.connected);
              Future.delayed(Duration.zero, () => _openWalletPage());
            } else {
              setState(() => _state = ConnectionState.connectionCancelled);
            }
          } catch (e) {
            print('WC exception occured: $e');
            setState(() => _state = ConnectionState.connectionFailed);
          }
        };
    }
  }

  Future<Contest?> getContestData() async {
    try {
      var data = await interface.get("/contest/get", serverType: ComInterface.serverDAO);
      Contest contest = Contest.fromJson(data);
      return contest;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(
          arc: false,
          mainMenu: true,
        ),
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Header(header: AppLocalizations.of(context)!.voting),
                    Column(children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.connect_wallet,
                              style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 16.0),
                            ),
                            FlatCustomButton(
                                width: 50,
                                height: 30,
                                radius: 7,
                                color: _state != ConnectionState.connected ? Colors.red : Colors.black12,
                                onTap: _transactionStateToAction(context, state: _state),
                                child: const Icon(
                                  Icons.wallet,
                                  color: Colors.white70,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<Contest?>(
                          future: getContestData(),
                          builder: (BuildContext context, AsyncSnapshot<Contest?> snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (snapshot.hasData) {
                              var contest = snapshot.data;
                              num amount = contest?.amountToReach ?? 0.0;
                              DateTime date = contest?.dateEnding ?? DateTime.parse(nullDate);
                              num total = 0;
                              contest?.entries?.forEach((element) {
                                total += element.amount!;
                              });
                              return ListView.builder(
                                itemCount: contest?.entries?.length ?? 0,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  var percentage = (contest!.entries![index].amount!.toDouble() / total.toDouble());
                                  percentage.isNaN ? percentage = 0.0 : percentage;
                                  var userPercent = contest.entries![index].userAmount!.toDouble() /contest.entries![index].amount!.toDouble() ;
                                  userPercent.isNaN ? userPercent = 0.0 : userPercent;
                                  return DataBar(
                                    title: contest.entries![index].name!,
                                    percentage: percentage,
                                    userPercentage: userPercent,
                                    amount: contest.entries![index].amount!.toDouble(),
                                    userAmount: contest.entries![index].userAmount!.toDouble(),
                                    index: index,
                                  );
                                },
                              );
                            } else {
                              return const Center(child: CircularProgressIndicator());
                            }
                          }),
                    ]),
                  ]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
