import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/bloc/stealth_tx_bloc.dart';
import 'package:digitalnote/models/StealthTX.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/DropdownMenu.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/send_stealth_widget.dart';
import 'package:digitalnote/widgets/stealth_tx_view.dart';
import 'package:digitalnote/widgets/token_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StealthScreen extends StatefulWidget {
  static const String route = "menu/stealth";

  const StealthScreen({Key? key}) : super(key: key);

  @override
  State<StealthScreen> createState() => _StealthScreenState();
}

class _StealthScreenState extends State<StealthScreen> with TickerProviderStateMixin {
  ComInterface interface = ComInterface();
  StealthTxBloc? _bloc;
  bool sendState = false;
  bool first = true;

  var listPos = 0;
  List<String> addrList = [];
  List<double> balanceList = [];
  late StealthTX stealthTX;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _bloc = StealthTxBloc();
    _bloc?.fetchTokenData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc?.dispose();
    super.dispose();
  }

  void showSendCard() {
    _controller.forward();
    setState(() {
      sendState = true;
    });
  }

  void hideSendCard() {
    _controller.reverse();
    setState(() {
      sendState = false;
    });
  }

  Widget _tab1(List<String> addrList) {
    if (addrList.isEmpty) {
      addrList = ["No addresses found"];
    }
    return Row(
      key: const ValueKey(1),
      children: [
        Card(
          elevation: 0,
          color: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.only(left: 2.0, right: 2.0),
            child: DropdownButtonHideUnderline(
              child: DrownDownMenu<String>(
                currentIndex: listPos,
                items: addrList.map((String value) {
                  return DropdownItem<String>(
                    value: value,
                    child: SizedBox(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.72,
                        height: 40,
                        child: Center(
                          child: AutoSizeText(
                            value,
                            maxLines: 1,
                            minFontSize: 8.0,
                            overflow: TextOverflow.ellipsis,
                            stepGranularity: 0.1,
                            style: Theme
                                .of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontSize: 14.0, color: Colors.white70, fontWeight: FontWeight.w500, fontFamily: 'RobotoMono'),
                          ),
                        )),
                  );
                }).toList(),
                onChange: (value, index) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                    listPos = index;
                  }));
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
        ),
        FlatCustomButton(
          height: 35,
          width: 35,
          onLongPress: () {
            getAddr();
          },
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Long press for new stealth address'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          },
          radius: 8,
          color: const Color(0xFF43864C),
          child: const Icon(
            Icons.add,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _tab2(String addr) {
    return Row(
      key: const ValueKey(2),
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            color: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.only(left: 2.0, right: 2.0),
              child: SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                height: 40,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0, bottom: 4.0),
                    child: AutoSizeText(
                      addr,
                      maxLines: 1,
                      minFontSize: 8.0,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontSize: 15.0, color: Colors.white70, fontWeight: FontWeight.w500, fontFamily: 'RobotoMono'),
                      stepGranularity: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: FlatCustomButton(
            height: 35,
            width: 35,
            onTap: () {
              // _bloc?.fetchTokenData();
              hideSendCard();
            },
            radius: 8,
            color: const Color(0xFF962E2E),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
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
                const Header(header: 'XDN Stealth'),
                StreamBuilder<ApiResponse<StealthTX>>(
                    stream: _bloc!.coinsListStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        switch (snapshot.data!.status) {
                          case Status.completed:
                            addrList.clear();
                            balanceList.clear();
                            if (first) {
                              first = false;
                              listPos = snapshot.data!.data!.rest!.indexWhere((element) => element.bal! > 0.0);
                              listPos < 0 ? listPos = 0 : listPos = listPos;
                            }
                            for (var element in snapshot.data!.data!.rest!) {
                              addrList.add(element.addr!);
                              balanceList.add(element.bal!);
                            }
                            stealthTX = snapshot.data!.data!;
                            return Column(
                              children: [
                                AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    child: sendState ? _tab2(addrList[listPos]) : _tab1(addrList)),
                                const SizedBox(
                                  width: 20,
                                ),
                                Stack(
                                  children: [
                                    TokenBalanceCard(
                                      key: const ValueKey(1),
                                      balance: stealthTX.rest?[listPos].bal?.toDouble(),
                                      send: () {
                                        showSendCard();
                                        // if (_state == ConState.connected) {
                                        //   Dialogs.openTokenSendingDialogs(context, _sendCoins);
                                        // } else {
                                        //   Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.error_connect_wallet);
                                        // }
                                      },
                                      address: stealthTX.rest?[listPos].addr ?? "null",
                                    ),
                                    IgnorePointer(
                                      ignoring: !sendState,
                                      child: FadeTransition(
                                        opacity: _animation,
                                        child: SendStealthWidget(
                                          balance: stealthTX.rest?[listPos].bal?.toDouble(),
                                          send: (addr, amount) {
                                            _sendCoins(address: addr, amount: amount);
                                          },
                                          address: stealthTX.rest?[listPos].addr ?? "null",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: snapshot.data?.data?.rest?[listPos].tx?.length ?? 0,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return StealthTxView(transaction: snapshot.data?.data?.rest?[listPos].tx?[index]);
                                      }),
                                ),
                              ],
                            );
                          case Status.loading:
                            return SizedBox(
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.6,
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 1,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                  backgroundColor: Colors.white24,
                                  strokeWidth: 1.0,
                                ),
                              ),
                            );
                          case Status.error:
                            print(snapshot.data!.message);
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

  void getAddr() async {
    ComInterface interface = ComInterface();
    try {
      Dialogs.openWaitBox(context);
      await interface.get("/user/stealth/addr", serverType: ComInterface.serverGoAPI, debug: true);
      _bloc?.fetchTokenData();
      if (mounted) Navigator.of(context).pop();
      if (mounted) Dialogs.openAlertBox(context, "Success", "Addition of stealth address added");
    } catch (e) {
      if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, e.toString());
      print(e);
    }
  }

  void _sendCoins({required String address, required String amount}) async {
  print("send coins");
    try {
      String method = "/user/stealth/send";
      String addr = address;
      String amnt = amount;
      String stealthAddr = addrList[listPos];
      double bal = balanceList[listPos];
      Map<String, dynamic>? m;
      if (double.parse(amnt) > bal) {
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "${AppLocalizations.of(context)!.st_insufficient}!");
        return;
      }

      if (double.parse(amnt) == 0.0) {
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.amount_empty);
        return;
      }

      if (!RegExp(r"^\b(d)[a-zA-Z0-9]{33}$").hasMatch(addr)) {
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.konj_addr_invalid);
        return;
      }
      Dialogs.openWaitBox(context);
      m = {
        "address": addr,
        "amount": double.parse(amnt),
        "stealth_addr": stealthAddr,
      };

      ComInterface interface = ComInterface();
      await interface.post(method, body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
      if (mounted) Navigator.of(context).pop();
      hideSendCard();
      _bloc?.fetchTokenData();
      if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.succ, "${AppLocalizations.of(context)!.sent} $amnt XDN!");
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, e.toString());
      print(e);
    }
  }
}
