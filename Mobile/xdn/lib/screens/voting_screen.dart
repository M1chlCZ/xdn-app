import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:digitalnote/models/Contest.dart';
import 'package:digitalnote/net_interface/app_exception.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/wallet_connector.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/data_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../models/DaoErrors.dart';
import '../widgets/backgroundWidget.dart';

enum ConState {
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

class _VotingScreenState extends State<VotingScreen> with TickerProviderStateMixin {
  ComInterface interface = ComInterface();
  WalletConnector connector = GetIt.I.get<WalletConnector>();
  AnimationController? _animationController;
  Animation<double>? _animation;
  String nullDate = "1970-00-01 00:00:01";
  bool detailsExtended = false;
  bool doneLoading = false;
  Timer? t;

  static const _networks = ['BNB'];

  ConState _state = ConState.disconnected;
  String? _networkName = _networks.first;

  @override
  void initState() {
    super.initState();
    initConnector();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController!, curve: Curves.fastLinearToSlowEaseIn));
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  initConnector() async {
    try {
      Map<String, dynamic>? m = await connector.getData();
      if (m != null) {
        _state = ConState.connected;

      }
    } catch (_) {}
    connector.registerListeners(
      // connected
            (session) {
          setState(() => _state = ConState.connected);
          print('Connected');
        },
        // session updated
            (response) => print('Session updated: $response'),
        // disconnected
            () {
          setState(() => _state = ConState.disconnected);
          print('Disconnected');
        });
    setState(() {});
  }

  String _transactionStateToString({required ConState state}) {
    switch (state) {
      case ConState.disconnected:
        return 'Connect!';
      case ConState.connecting:
        return 'Connecting';
      case ConState.connected:
        return 'Session connected';
      case ConState.connectionFailed:
        return 'Connection failed';
      case ConState.connectionCancelled:
        return 'Connection cancelled';
    }
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

  Future<Contest?> getContestData() async {
    try {
      var data = await interface.get("/contest/get", serverType: ComInterface.serverDAO);
      Contest contest = Contest.fromJson(data);
      t ??= Timer.periodic(const Duration(seconds: 10), (Timer t) {
        setState(() {});
      });
      return contest;
    } on ConflictDataException catch (e) {
      DaoErrors error = DaoErrors.fromJson(json.decode(e.toString()));
      if (error.errorMessage == "No contest") {
        return Future.error(AppLocalizations.of(context)!.no_contest);
      }
      return Future.error("no contest");
    } catch (e) {
      debugPrint(e.toString());
      return Future.error("no contest");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(
          arc: false,
          mainMenu: false,
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
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(fontSize: 16.0),
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
                            decoration: const BoxDecoration(
                              color: Colors.lime,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.wallet_connected,
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .bodyText1!
                                          .copyWith(fontSize: 14.0, color: Colors.black87),
                                    ),
                                    Text(
                                      Utils.formatWallet(connector.address),
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .headline1!
                                          .copyWith(fontSize: 14.0, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: const BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                            ),
                            child: FutureBuilder<Map<String, dynamic>?>(
                                future: connector.getData(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final balance = snapshot.data;
                                    // print("balance $balance");
                                    return Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        SizeTransition(
                                          sizeFactor: _animation!,
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(context)!.wl_balance,
                                                    style: Theme
                                                        .of(context)
                                                        .textTheme
                                                        .bodyText1!
                                                        .copyWith(fontSize: 14.0),
                                                  ),
                                                  Row(
                                                    children: [
                                                      AutoSizeText(
                                                        NumberFormat('#,###').format(balance!['xdn']).replaceAll(",", " "),
                                                        maxLines: 1,
                                                        minFontSize: 8,
                                                        style: Theme
                                                            .of(context)
                                                            .textTheme
                                                            .headline1!
                                                            .copyWith(fontSize: 14.0),
                                                      ),
                                                      const SizedBox(
                                                        width: 4.0,
                                                      ),
                                                      const CoinBadge(text: '2XDN'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(context)!.bnb_balance,
                                                    style: Theme
                                                        .of(context)
                                                        .textTheme
                                                        .bodyText1!
                                                        .copyWith(fontSize: 14.0),
                                                  ),
                                                  Row(
                                                    children: [
                                                      AutoSizeText(
                                                        balance['bnb'].toString(),
                                                        maxLines: 1,
                                                        minFontSize: 8,
                                                        style: Theme
                                                            .of(context)
                                                            .textTheme
                                                            .headline1!
                                                            .copyWith(fontSize: 14.0),
                                                      ),
                                                      const SizedBox(
                                                        width: 4.0,
                                                      ),
                                                      const CoinBadge(text: 'BNB'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(context)!.gas,
                                                    style: Theme
                                                        .of(context)
                                                        .textTheme
                                                        .bodyText1!
                                                        .copyWith(fontSize: 14.0),
                                                  ),
                                                  Row(
                                                    children: [
                                                      AutoSizeText(
                                                        balance['gas'].toString(),
                                                        maxLines: 1,
                                                        minFontSize: 8,
                                                        style: Theme
                                                            .of(context)
                                                            .textTheme
                                                            .headline1!
                                                            .copyWith(fontSize: 14.0),
                                                      ),
                                                      const SizedBox(
                                                        width: 4.0,
                                                      ),
                                                      const CoinBadge(text: 'BNB'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (detailsExtended) {
                                              _animationController!.reverse();
                                              detailsExtended = false;
                                            } else {
                                              _animationController!.forward();
                                              detailsExtended = true;
                                            }
                                            setState(() {});
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Column(
                                                children: [
                                                  const SizedBox(
                                                    height: 1.0,
                                                  ),
                                                  Text(
                                                    detailsExtended ? AppLocalizations.of(context)!.st_less : AppLocalizations.of(context)!.st_more,
                                                    // textAlign: TextAlign.end,
                                                    style: Theme
                                                        .of(context)
                                                        .textTheme
                                                        .bodyText1!
                                                        .copyWith(fontSize: 9.0, color: Colors.white70),
                                                  ),
                                                  const SizedBox(
                                                    height: 10.0,
                                                  ),
                                                  // RotatedBox(
                                                  //   quarterTurns: _detailsExtended ? 2 : 0,
                                                  //   child: const Icon(
                                                  //     Icons.arrow_drop_down,
                                                  //     color: Colors.white54,
                                                  //     size: 18.0,
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else if (snapshot.hasError) {
                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.black.withOpacity(0.5),
                                      child: const Center(
                                        child: Text(
                                          "No contest",
                                          style: TextStyle(color: Colors.white, fontSize: 20),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Container();
                                  }
                                }),
                          ),
                        ]),
                      const SizedBox(height: 10),
                      FutureBuilder<Contest?>(
                          future: getContestData(),
                          builder: (BuildContext context, AsyncSnapshot<Contest?> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && doneLoading == false) {
                              return SizedBox(
                                width: double.infinity,
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.5,
                                child: const Center(
                                    child: SizedBox(
                                        width: 25,
                                        height: 25,
                                        child: CircularProgressIndicator(
                                          color: Colors.white54,
                                          strokeWidth: 1.0,
                                        ))),
                              );
                            } else {
                              doneLoading = true;
                              if (snapshot.hasError) {
                                return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    width: double.infinity,
                                    height: MediaQuery
                                        .of(context)
                                        .size
                                        .height * 0.2,
                                    child: Center(child: Text(snapshot.error.toString().capitalize(), textAlign: TextAlign.center, style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline1!
                                        .copyWith(fontSize: 24.0, color: Colors.white30),)));
                              } else if (snapshot.hasData) {
                                var contest = snapshot.data;
                                var name = contest?.contestName ?? "";
                                num amount = contest?.amountToReach ?? 0.0;
                                DateTime date = Utils.convertDateTime(contest?.dateEnding);
                                num total = 0;
                                contest?.entries?.forEach((element) {
                                  if (element.goal == 0) {
                                    total += element.amount!;
                                  }
                                });
                                return Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                      width: double.infinity,
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.2),
                                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                                            ),
                                            child: Text(
                                              name,
                                              textAlign: TextAlign.center,
                                              style: Theme
                                                  .of(context)
                                                  .textTheme
                                                  .bodyText1!
                                                  .copyWith(fontSize: 16.0, fontWeight: FontWeight.bold),
                                            )),
                                        Container(
                                          color: Colors.black12,
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                          child: Column(children: [
                                            const SizedBox(height: 3),
                                            if (amount != 0.0)
                                              Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      AutoSizeText(
                                                        "${AppLocalizations.of(context)!.amount_to_reach}: ",
                                                        maxLines: 1,
                                                        minFontSize: 8,
                                                        style: Theme
                                                            .of(context)
                                                            .textTheme
                                                            .bodyText1!
                                                            .copyWith(fontSize: 15.0, color: Colors.white),
                                                      ),
                                                      Row(
                                                        children: [
                                                          AutoSizeText(
                                                            NumberFormat('#,##,000').format(amount),
                                                            maxLines: 1,
                                                            minFontSize: 8,
                                                            style: Theme
                                                                .of(context)
                                                                .textTheme
                                                                .headline1!
                                                                .copyWith(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
                                                          ),
                                                          const SizedBox(width: 5),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.black.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: const Text(
                                                              '2XDN',
                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white30),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      AutoSizeText(
                                                        "${AppLocalizations.of(context)!.amount_reached}: ",
                                                        maxLines: 1,
                                                        minFontSize: 8,
                                                        style: Theme
                                                            .of(context)
                                                            .textTheme
                                                            .bodyText1!
                                                            .copyWith(fontSize: 15.0, color: Colors.white),
                                                      ),
                                                      Row(
                                                        children: [
                                                          AutoSizeText(
                                                            NumberFormat('#,##,000').format(total),
                                                            maxLines: 1,
                                                            minFontSize: 8,
                                                            style: Theme
                                                                .of(context)
                                                                .textTheme
                                                                .headline1!
                                                                .copyWith(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
                                                          ),
                                                          const SizedBox(width: 5),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.black.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: const Text(
                                                              '2XDN',
                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white30),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            if (date != DateTime.parse(nullDate))
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(context)!.date_ending,
                                                    style: Theme
                                                        .of(context)
                                                        .textTheme
                                                        .bodyText1!
                                                        .copyWith(fontSize: 12.0),
                                                  ),
                                                  // Text(
                                                  //   DateFormat('dd/MM/yyyy').format(date),
                                                  //   style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 12.0),
                                                  // ),
                                                ],
                                              ),
                                            StreamBuilder(
                                              stream: Stream.periodic(const Duration(seconds: 1)),
                                              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                return Text(convertDate(date).toString());
                                              },
                                            ),
                                          ]),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.2),
                                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Center(
                                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                Text(
                                                  AppLocalizations.of(context)!.st_live,
                                                  style: Theme
                                                      .of(context)
                                                      .textTheme
                                                      .headline5!
                                                      .copyWith(fontSize: 12.0, fontWeight: FontWeight.w300, color: Colors.white70),
                                                ),
                                                const SizedBox(
                                                  width: 4.0,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 1.0),
                                                  child: AvatarGlow(
                                                      glowColor: Colors.green,
                                                      endRadius: 8.5,
                                                      duration: const Duration(milliseconds: 1500),
                                                      repeat: true,
                                                      showTwoGlows: true,
                                                      curve: Curves.easeOut,
                                                      repeatPauseDuration: const Duration(milliseconds: 100),
                                                      child: Container(
                                                        height: 6.0,
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.withOpacity(0.7),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      )),
                                                ),
                                              ]),
                                            ),
                                          ),
                                        )
                                      ]),
                                    ),
                                    const SizedBox(height: 5),
                                    ListView.builder(
                                      itemCount: contest?.entries?.length ?? 0,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        var percentage = 0.0;
                                        var userPercent = 0.0;
                                        var goal = contest!.entries![index].goal!.toInt();
                                        if (goal == 0) {
                                          percentage = (contest.entries![index].amount!.toDouble() / total.toDouble());
                                          userPercent = contest.entries![index].userAmount!.toDouble() / contest.entries![index].amount!.toDouble();
                                        } else {
                                          percentage = (contest.entries![index].amount!.toDouble() / goal.toDouble());
                                          userPercent = contest.entries![index].userAmount!.toDouble() / contest.entries![index].amount!.toDouble();
                                        }
                                        percentage.isNaN ? percentage = 0.0 : percentage;
                                        userPercent.isNaN ? userPercent = 0.0 : userPercent;
                                        var id = contest.entries![index].id;

                                        return DataBar(
                                          address: contest.entries![index].address!,
                                          title: contest.entries![index].name!,
                                          percentage: percentage,
                                          userPercentage: userPercent,
                                          amount: contest.entries![index].amount!.toDouble(),
                                          userAmount: contest.entries![index].userAmount!.toDouble(),
                                          idEntry: id!.toInt(),
                                          index: index,
                                          callBack: (address, idEntry) {
                                            if (_state == ConState.connected) {
                                              Dialogs.openVotingDialogs(context, address, idEntry, _sendCoins);
                                            } else {
                                              Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.error_connect_wallet);
                                            }
                                          },
                                          goal: goal,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    const VotingLegend(),
                                  ],
                                );
                              } else {
                                return Container();
                              }
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

  String convertDate(DateTime dt) {
    final dateNow = DateTime.now();
    DateTime? fix;
    if (dateNow.timeZoneOffset.isNegative) {
      fix = dt.subtract(Duration(hours: dateNow.timeZoneOffset.inHours));
    } else {
      fix = dt.add(Duration(hours: dateNow.timeZoneOffset.inHours));
    }
    final sec = fix.difference(dateNow);
    var days = sec.inDays;
    var hours = sec.inHours % 24;
    var minutes = sec.inMinutes % 60;
    var seconds = sec.inSeconds % 60;
    return "${days < 10 ? "0$days" : "$days"}d : ${hours < 10 ? "0$hours" : "$hours"}h : ${minutes < 10 ? "0$minutes" : "$minutes"}m : ${seconds < 10 ? "0$seconds" : "$seconds"}s";
  }

  var tx = false;

  void _sendCoins(String address, int amount, int idEntry) async {
    if (tx) return;
    Navigator.of(context).pop();
    tx = true;
    Future.delayed(Duration.zero, () => connector.openWalletApp());
    String? s = await connector.sendTestingAmount(recipientAddress: address, amount: amount.toDouble());
    if (s != null) {
      setState(() {});
      var succ = await vote(idEntry, amount);
      if (succ) {
        Future.delayed(const Duration(milliseconds: 500), () => Dialogs.openAlertBox(context, AppLocalizations.of(context)!.succ, AppLocalizations.of(context)!.vot_succ));
      } else {
        Future.delayed(Duration.zero, () => Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.vot_fail));
      }
      tx = false;
    } else {
      print("no response");
      tx = false;
    }
  }

  Future<bool> vote(int idEntry, int amount) async {
    Map<String, dynamic> m = {
      "idEntry": idEntry,
      "amount": amount,
    };

    try {
      await interface.post("/contest/vote", debug: true, serverType: ComInterface.serverDAO, body: {
        "idEntry": idEntry,
        "amount": amount,
      }, request: {});
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> saveAddress(String address) async {
    try {
      await interface.post("/user/address/add", debug: true, serverType: ComInterface.serverDAO, body: {
        "address": address,
      }, request: {});
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}

class CoinBadge extends StatelessWidget {
  final String text;

  const CoinBadge({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white30),
      ),
    );
  }
}

class VotingLegend extends StatelessWidget {
  const VotingLegend({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 3,
                  color: Colors.blue,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  AppLocalizations.of(context)!.amount_of_votes,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyText1!
                      .copyWith(fontSize: 8.0),
                ),
              ],
            ),
            const SizedBox(
              width: 10,
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 3,
                  color: Colors.green,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  AppLocalizations.of(context)!.amount_of_votes_user,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyText1!
                      .copyWith(fontSize: 8.0),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}
