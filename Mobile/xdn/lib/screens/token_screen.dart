import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/bloc/token_tx_bloc.dart';
import 'package:digitalnote/models/TokenTx.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/wallet_connector.dart';
import 'package:digitalnote/support/wxdn_connector.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/DropdownMenu.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/token_balance_card.dart';
import 'package:digitalnote/widgets/token_tx_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

enum ConState {
  disconnected,
  connecting,
  connected,
  connectionFailed,
  connectionCancelled,
}

class TokenScreen extends StatefulWidget {
  static const String route = "menu/token";

  const TokenScreen({Key? key}) : super(key: key);

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  ComInterface interface = ComInterface();
  WalletConnector connector = GetIt.I.get<WXDConnector>();
  ConState _state = ConState.disconnected;
  TokenTxBloc? _bloc;

  var listPos = 0;

  @override
  void initState() {
    super.initState();
    initConnector();
    _bloc = TokenTxBloc();
    _bloc?.fetchTokenData();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  initConnector() async {
    try {

      Map<String, dynamic>? m = await connector.getData();
      if (m != null) {
        _state = ConState.connected;
      }
    } catch (_) {}
    connector.registerListeners(
        (session) {
          setState(() => _state = ConState.connected);
          debugPrint('Connected');
        },
        (response) => debugPrint('Session updated: $response'),
        () {
          setState(() => _state = ConState.disconnected);
          debugPrint('Disconnected');
        });
    setState(() {});
  }

  void _openWalletPage() {
    saveAddress(connector.address);
    setState(() {});
  }

  VoidCallback? _transactionStateToAction(BuildContext context, {required ConState state}) {
    switch (state) {
      // Progress, action disabled
      case ConState.connecting:
        return null;
      case ConState.connected:
        // Open new page
        return () => _openWalletPage();

      // Initiate the connection
      case ConState.disconnected:
      case ConState.connectionCancelled:
      case ConState.connectionFailed:
        return () async {
          setState(() => _state = ConState.connecting);
          try {
            final session = await connector.connect(context);
            if (session != null) {
              setState(() => _state = ConState.connected);
              Future.delayed(Duration.zero, () => _openWalletPage());
            } else {
              setState(() => _state = ConState.connectionCancelled);
            }
          } catch (e) {
            print('WC exception occured: $e');
            setState(() => _state = ConState.connectionFailed);
          }
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        arc: false,
        mainMenu: false,
      ),
      Builder(builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Header(header: 'WXDN ${AppLocalizations.of(context)!.wl_balance}'),
                Column(
                  children: [
                    if (_state != ConState.connected) //not connected
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
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16.0),
                            ),
                            FlatCustomButton(
                                width: 50,
                                height: 30,
                                radius: 7,
                                color: _state != ConState.connected ? Colors.red : Colors.black12,
                                onTap: _transactionStateToAction(context, state: _state),
                                child: const Icon(
                                  Icons.wallet,
                                  color: Colors.white70,
                                )),
                          ],
                        ),
                      ),
                    if (_state == ConState.connected) //connected
                      Column(children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.lime,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.wallet_connected,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.black87),
                                  ),
                                  Text(
                                    Utils.formatWallet(connector.address),
                                    style: Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 14.0, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ]),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<ApiResponse<TokenTx>>(
                    stream: _bloc!.coinsListStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        switch (snapshot.data!.status) {
                          case Status.completed:
                            listPos = snapshot.data!.data!.rest!.indexWhere((element) => element.bal! > 0.0);
                            listPos < 0 ? listPos = 0 : listPos = listPos;
                            List<String> addrList = [];
                            for (var element in snapshot.data!.data!.rest!) {
                                addrList.add(element.addr!);
                            }
                            return Column(
                              children: [
                                Card(
                                  elevation: 0,
                                  color: Colors.black12,
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  child: DropdownButtonHideUnderline(
                                    child: DrownDownMenu<String>(
                                      currentIndex: listPos,
                                      items: addrList.map((String value) {
                                        return DropdownItem<String>(
                                          value: value,
                                          child: SizedBox(
                                            width: MediaQuery.of(context).size.width *0.80,
                                              height: 40,
                                              child: Center(
                                                child: AutoSizeText(
                                                  value,
                                                  maxLines: 1,
                                                  minFontSize: 6.0,
                                                  overflow: TextOverflow.ellipsis,
                                                  stepGranularity: 0.1,
                                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white70, fontWeight: FontWeight.w500, fontFamily: 'RobotoMono'),
                                                ),
                                              )
                                          ),
                                        );
                                      }).toList(),
                                      onChange: (value, index) {
                                        setState(() {
                                          listPos = addrList.indexOf(value);
                                        });
                                      },
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                                      dropdownButtonStyle: const DropdownButtonStyle(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        height: 40,
                                        elevation: 0,
                                        backgroundColor: Colors.transparent,
                                        primaryColor: Colors.white70,
                                      ),
                                      dropdownStyle: DropdownStyle(
                                        borderRadius: BorderRadius.circular(8),
                                        elevation: 6,
                                        padding: const EdgeInsets.all(10),
                                        color: const Color(0xFF2B3752),
                                      ),
                                      child: const Text(
                                        '',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TokenBalanceCard(
                                  balance: snapshot.data?.data?.rest?[listPos].bal?.toDouble(),
                                  send: () {
                                    if (_state == ConState.connected) {
                                      Dialogs.openTokenSendingDialogs(context, _sendCoins);
                                    } else {
                                      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.error_connect_wallet);
                                    }
                                  },
                                  address: snapshot.data?.data?.rest?[listPos].addr ?? "null",
                                ),
                                const SizedBox(height: 10),
                                ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: snapshot.data?.data?.rest?[listPos].tx?.length ?? 0,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return TokenTxView(address: snapshot.data?.data?.rest?[listPos].addr ?? "null", transaction: snapshot.data?.data?.rest?[listPos].tx?[index]);
                                    }),
                              ],
                            );
                          case Status.loading:
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              width: MediaQuery.of(context).size.width * 1,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                  backgroundColor: Colors.white24,
                                  strokeWidth: 1.0,
                                ),
                              ),
                            );
                          case Status.error:
                            return Container();
                        }
                      } else {
                        return Container();
                      }
                    }),
              ]),
            ),
          ),
        );
      })
    ]);
  }

  Future<bool> saveAddress(String address) async {
    try {
      await interface.post("/user/address/add", debug: false, serverType: ComInterface.serverDAO, body: {
        "address": address,
      }, request: {});
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  var tx = false;
  void _sendCoins(String address, int amount) async {
    if (tx) return;
    Navigator.of(context).pop();
    tx = true;
    Future.delayed(Duration.zero, () => connector.openWalletApp());
    String? s = await connector.sendTestingAmount(recipientAddress: address, amount: amount.toDouble());
    if (s != null) {
      _bloc?.fetchTokenData();
     // TODO: Stuff
      tx = false;
    } else {
      print("no response");
      tx = false;
    }
  }
}
