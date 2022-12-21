import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/bloc/token_tx_bloc.dart';
import 'package:digitalnote/models/TokenTx.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/DropdownMenu.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/token_balance_card.dart';
import 'package:digitalnote/widgets/token_tx_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class StealthScreen extends StatefulWidget {
  static const String route = "menu/stealth";

  const StealthScreen({Key? key}) : super(key: key);

  @override
  State<StealthScreen> createState() => _StealthScreenState();
}

class _StealthScreenState extends State<StealthScreen> {
  ComInterface interface = ComInterface();
  TokenTxBloc? _bloc;

  var listPos = 0;

  @override
  void initState() {
    super.initState();
    _bloc = TokenTxBloc();
    _bloc?.fetchTokenData();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
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
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                                    child: DropdownButtonHideUnderline(
                                      child: DrownDownMenu<String>(
                                        currentIndex: listPos,
                                        items: addrList.map((String value) {
                                          return DropdownItem<String>(
                                            value: value,
                                            child: SizedBox(
                                                width: MediaQuery.of(context).size.width * 0.82,
                                                height: 40,
                                                child: Center(
                                                  child: AutoSizeText(
                                                    value,
                                                    maxLines: 1,
                                                    minFontSize: 8.0,
                                                    overflow: TextOverflow.ellipsis,
                                                    stepGranularity: 0.1,
                                                    style:
                                                        Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white70, fontWeight: FontWeight.w500, fontFamily: 'RobotoMono'),
                                                  ),
                                                )),
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
                                ),
                                TokenBalanceCard(
                                  balance: snapshot.data?.data?.rest?[listPos].bal?.toDouble(),
                                  send: () {
                                    // if (_state == ConState.connected) {
                                    //   Dialogs.openTokenSendingDialogs(context, _sendCoins);
                                    // } else {
                                    //   Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.error_connect_wallet);
                                    // }
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
}
