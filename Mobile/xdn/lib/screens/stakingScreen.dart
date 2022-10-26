import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:decimal/decimal.dart';
import 'package:digitalnote/bloc/stake_graph_bloc.dart';
import 'package:digitalnote/models/StakeCheck.dart';
import 'package:digitalnote/models/staking_data.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/auto_size_text_field.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/coin_stake_graph.dart';
import 'package:digitalnote/widgets/percent_switch_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../globals.dart' as globals;
import '../support/ColorScheme.dart';
import '../support/Dialogs.dart';
import '../support/LifecycleWatcherState.dart';
import '../support/NetInterface.dart';
import '../widgets/DropdownMenu.dart';
import '../widgets/backgroundWidget.dart';

class StakingScreen extends StatefulWidget {
  static const String route = "menu/staking";

  const StakingScreen({Key? key}) : super(key: key);

  @override
  StakingScreenState createState() => StakingScreenState();
}

class StakingScreenState extends LifecycleWatcherState<StakingScreen> {
  var _dropdownValue = 0;
  Future? _getBalanceFuture;
  final _graphKey = GlobalKey<CoinStakeGraphState>();
  final _percentageKey = GlobalKey<PercentSwitchWidgetState>();
  final GlobalKey<SlideActionState> _keyStake = GlobalKey();
  final _controller = TextEditingController();
  StreamSubscription? _fcmSubscription;
  StakeGraphBloc? _stakeBloc;
  List<FlSpot>? values = [];

  int endTime = 0;
  String _lockedText = '';
  int _serverStatus = 0;

  String _balance = "";
  String _imature = "";
  String _pending = "";
  bool _staking = false;
  bool _paused = false;
  bool _imatureVisible = false;
  bool _pendingVisible = false;
  bool _hideLoad = false;
  int _countNot = 0;
  bool _awaitingNot = false;
  double _totalCoins = 0.0;
  double _contribution = 0.0;
  double _estimated = 0.0;
  double _locked = 0.0;
  double _reward = 0.0;
  double _stakeAmount = 0.0;
  Timer? t;
  int _typeGraph = 0;

  @override
  void initState() {
    super.initState();
    _getBalance();
    _checkCountdown();
    t = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      if (!_paused && mounted) {
        if (_dropdownValue == 0) {
          _getBalance();
          _stakeBloc!.fetchStakeData(_dropdownValue);
          // _graphByDay();
        }
      } else {
        t.cancel();
      }
    });
    _controller.addListener(() {
      _percentageKey.currentState!.deActivate();
    });

    _stakeBloc = StakeGraphBloc();
    _stakeBloc!.stakeBloc();
    _stakeBloc!.fetchStakeData(_typeGraph);

    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // print('Got a message whilst in the foreground!');
      // print('Message data: ${message.data}');
      _not();
      if (message.notification != null) {
        // print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    t?.cancel();
    _stakeBloc?.dispose();
    _fcmSubscription?.cancel();
    super.dispose();
  }

  void _not() async {
    if (!_awaitingNot) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _getBalance();
          _countNot = 0;
          _awaitingNot = false;
        });
      });
      return;
    }
    if (_countNot == 0) {
      _countNot++;
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _getBalance();
          _countNot = 0;
          _awaitingNot = false;
        });
        _keyStake.currentState!.reset();
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 50), () {
          FocusScope.of(context).unfocus();
        });
      });
    }
  }

  _changePercentage(double d) {
    _controller.text = _formatPriceString(((double.parse(_balance)) * d).toString());
    setState(() {});
  }

  String _formatPriceString(String d) {
    try {
      var split = d.toString().split('.');
      var decimal = split[1];
      if (decimal.length >= 9) {
        var sub = decimal.substring(0, 8);
        return ("${split[0]}.$sub").trim();
      } else {
        return d.toString().trim();
      }
    } catch (e) {
      return "0";
    }
  }

  void _sendStakeCoins(String amount) async {
    try {
      double amnt = double.parse(amount) - 0.01;
      if (amnt == 0) {
        _keyStake.currentState!.reset();
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, AppLocalizations.of(context)!.amount_empty);
      } else if (double.parse(_balance) < double.parse(amount)) {
        _keyStake.currentState!.reset();
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, AppLocalizations.of(context)!.st_insufficient);
      } else if (amnt < 0) {
        _keyStake.currentState!.reset();
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.st_in_fees);
      } else {
        Dialogs.openWaitBox(context);

        _serverStatus = await NetInterface.sendStakeCoins(amnt.toString());
        if (_serverStatus == 2) {
          if (mounted) {
            _keyStake.currentState!.reset();
            Navigator.of(context).pop();
            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.st_cannot_stake);
          }
          return;
        } else if (_serverStatus == 4) {
          if (mounted) {
            _keyStake.currentState!.reset();
            Navigator.of(context).pop();
            Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.st_not_balance);
          }
          return;
        }
        var endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 86400;
        SecureStorage.write(key: globals.COUNTDOWN, value: endTime.toString());
        setState(() {
          endTime = endTime;
          FocusScope.of(context).unfocus();
        });
        _awaitingNot = true;
        _controller.clear();

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_awaitingNot) {
            setState(() {
              _awaitingNot = false;
              _countNot = 0;
              _getBalance();
              // Navigator.of(context).pop();
            });
            Navigator.of(context).pop();
            _keyStake.currentState!.reset();
            Future.delayed(const Duration(milliseconds: 50), () {
              FocusScope.of(context).unfocus();
            });
          }
        });
      }
    } catch (e) {
      Navigator.of(context).pop();
      _keyStake.currentState!.reset();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, AppLocalizations.of(context)!.amount_empty);
    }
  }

  void _unstakeCoins(int type) async {
    Dialogs.openWaitBox(context);
    var i = await NetInterface.unstakeCoins(type);
    _awaitingNot = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_awaitingNot) {
        setState(() {
          _awaitingNot = false;
          _countNot = 0;
          _getBalance();

          // Navigator.of(context).pop();
        });
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 50), () {
          FocusScope.of(context).unfocus();
        });
      }
    });
    if (i == 2) {
      if (mounted) {
        Navigator.of(context).pop();
        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, AppLocalizations.of(context)!.st_24h_timeout);
      }
      return;
    }
  }

  void _getBalance() async {
    _getBalanceFuture = NetInterface.getBalance(details: true);
    setState(() {});
    await _getStakingDetails();
  }

  Future<void> _getStakingDetails() async {
    ComInterface interface = ComInterface();
    var res = await interface.get("/staking/info", debug: true, serverType: ComInterface.serverGoAPI, request: {});
    StakeCheck? sc = StakeCheck.fromJson(res);
    if (sc.hasError == true) return;
    if (sc.active == 0) {
      _staking = false;
      _totalCoins = sc.inPoolTotal ?? 0.0;
      _hideLoad = true;
      setState(() {});
    } else {
      _estimated = sc.estimated ?? 0.0;
      _contribution = sc.contribution ?? 0.0;
      _totalCoins = sc.inPoolTotal ?? 0.0;
      _locked = sc.amount ?? 0.0;
      _stakeAmount = sc.amount ?? 0.0;
      _reward = Decimal.parse(sc.stakesAmount!.toString()).toDouble();
      _staking = true;
      _hideLoad = true;
      setState(() {});
    }
  }

  double _dp(double val, int places) {
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  void _checkCountdown() async {
    var countDown = await SecureStorage.read(key: globals.COUNTDOWN);
    if (countDown != null) {
      int nowDate = DateTime.now().millisecondsSinceEpoch;
      int countTime = int.parse(countDown);
      if (nowDate < countTime) {
        setState(() {
          _lockedText = AppLocalizations.of(context)!.st_locked_coins;
          endTime = int.parse(countDown);
        });
      } else {
        setState(() {
          _lockedText = AppLocalizations.of(context)!.st_coins_staked;
        });
      }
    }else{
      setState(() {
        _lockedText = AppLocalizations.of(context)!.st_coins_staked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        mainMenu: false,
      ),
      Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(children: [
              Header(
                header: AppLocalizations.of(context)!.st_headline.toUpperCase(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0, right: 3.0, bottom: 3.0),
                child: ClipRect(
                  child: Container(
                    padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                    decoration: BoxDecoration(color: const Color(0xFF262C43), border: Border.all(color: Colors.transparent), borderRadius: const BorderRadius.all(Radius.circular(10.0))),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: DrownDownMenu<int>(
                            hideIcon: false,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white30,
                              size: 20,
                            ),
                            currentIndex: _dropdownValue,
                            onChange: (int value, int index) {
                              _dropdownValue = index;
                              switch (index) {
                                case 0:
                                  _typeGraph = 0;
                                  _stakeBloc!.fetchStakeData(_dropdownValue);
                                  // _graphByDay();
                                  break;
                                case 1:
                                  _typeGraph = 2;
                                  _stakeBloc!.fetchStakeData(_typeGraph);
                                  // _graphByMonth();
                                  break;
                                case 2:
                                  // _graphByYear();
                                  break;
                              }
                              setState(() {});
                            },
                            dropdownButtonStyle: DropdownButtonStyle(
                              mainAxisAlignment: MainAxisAlignment.start,
                              width: 300,
                              height: 40,
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              primaryColor: Theme.of(context).konjCardColor,
                            ),
                            dropdownStyle: DropdownStyle(
                              borderRadius: BorderRadius.circular(8),
                              elevation: 6,
                              padding: const EdgeInsets.all(5),
                              color: const Color(0xFF2B3752),
                            ),
                            items: [
                              AppLocalizations.of(context)!.st_coins_today,
                              AppLocalizations.of(context)!.st_coins_week,
                            ]
                                .asMap()
                                .entries
                                .map(
                                  (item) => DropdownItem<int>(
                                    value: item.key + 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(item.value, style: Theme.of(context).textTheme.button!.copyWith(fontSize: 16.0, color: Colors.white70)),
                                    ),
                                  ),
                                )
                                .toList(),
                            child: const Text(
                              'dropdown',
                            ),
                          ),
                        ),
                        Stack(
                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0, left: 5),
                                    child: SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.2,
                                        width: MediaQuery.of(context).size.width * 0.92,
                                        child: StreamBuilder<ApiResponse<StakingData>>(
                                            stream: _stakeBloc!.coinsListStream,
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                switch (snapshot.data!.status) {
                                                  case Status.completed:
                                                    return CoinStakeGraph(
                                                      key: _graphKey,
                                                      stake: snapshot.data?.data,
                                                      type: _typeGraph,
                                                      blockTouch: (b) {
                                                        // setState(() {
                                                        //   _liveVisible = b ? 0 : 1;
                                                        // });
                                                      },
                                                    );
                                                  case Status.loading:
                                                    return SizedBox(
                                                      width: double.infinity,
                                                      height: MediaQuery.of(context).size.height * 0.5,
                                                      child: const Center(
                                                          child: SizedBox(
                                                              width: 25,
                                                              height: 25,
                                                              child: CircularProgressIndicator(
                                                                color: Colors.white54,
                                                                strokeWidth: 1.0,
                                                              ))),
                                                    );
                                                  case Status.error:
                                                    return Container(
                                                      color: Colors.transparent,
                                                      child: Align(
                                                        alignment: Alignment.bottomCenter,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Text(
                                                            AppLocalizations.of(context)!.graph_no_data,
                                                            style: Theme.of(context).textTheme.subtitle2!.copyWith(color: Colors.red),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  default:
                                                    return Container();
                                                }
                                              } else {
                                                return Container();
                                              }
                                            })))),
                            Positioned(
                              right: 20,
                              top: 10,
                              child: AnimatedOpacity(
                                opacity: _dropdownValue == 0 ? 1 : 0,
                                duration: const Duration(milliseconds: 500),
                                child: Row(
                                  children: [
                                    AvatarGlow(
                                        glowColor: Colors.white,
                                        endRadius: 5.5,
                                        duration: const Duration(milliseconds: 1500),
                                        repeat: true,
                                        showTwoGlows: true,
                                        curve: Curves.easeOut,
                                        repeatPauseDuration: const Duration(milliseconds: 100),
                                        child: Container(
                                          height: 5.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                        )),
                                    const SizedBox(
                                      width: 2.0,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.st_live.toUpperCase(),
                                      style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, fontWeight: FontWeight.w300, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Stack(
                children: [
                  ClipRect(
                      child: Container(
                    margin: const EdgeInsets.only(left: 2.0, right: 2.0),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                      border: Border.all(color: Theme.of(context).konjHeaderColor),
                      color: const Color(0xFF262C43),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 17.0, right: 25.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 150,
                                child: AutoSizeText(AppLocalizations.of(context)!.available, maxLines: 1, minFontSize: 8.0, style: Theme.of(context).textTheme.headline5),
                              ),
                              FutureBuilder(
                                  future: _getBalanceFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      Map m = snapshot.data as Map<String, dynamic>;
                                      _balance = double.parse(m['spendable'].toString()).toStringAsFixed(3);
                                      _imature = double.parse(m['immature'].toString()).toStringAsFixed(3);
                                      _pending = double.parse(m['balance'].toString()).toStringAsFixed(3);
                                      t = Timer(const Duration(milliseconds: 100), () {
                                        setState(() {
                                          _imatureVisible = _imature == "0.000" ? false : true;
                                          _pendingVisible = double.parse(m['balance'].toString()).toInt() == 0 ? false : true;
                                          if (_imatureVisible && _pendingVisible) {
                                            _pendingVisible = false;
                                          }
                                          t!.cancel();
                                        });
                                      });
                                      return Expanded(
                                        child: AutoSizeText(
                                          "$_balance XDN",
                                          minFontSize: 8.0,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          textAlign: TextAlign.right,
                                          style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 20.0),
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                        snapshot.error.toString(),
                                        style: GoogleFonts.montserrat(fontStyle: FontStyle.normal, fontSize: 24, color: Colors.red),
                                      ));
                                    } else {
                                      return Center(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: const <Widget>[
                                          SizedBox(
                                              height: 24.0,
                                              width: 24.0,
                                              child: CircularProgressIndicator(
                                                backgroundColor: Colors.white54,
                                                strokeWidth: 0.5,
                                              )),
                                        ]),
                                      );
                                    }
                                  }),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _imatureVisible,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, left: 17.0, right: 25.0),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(AppLocalizations.of(context)!.immature, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0, color: Colors.white38)),
                              Expanded(
                                child: AutoSizeText("$_imature XDN",
                                    minFontSize: 8.0,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 14.0, color: Colors.white38)),
                              )
                            ]),
                          ),
                        ),
                        Visibility(
                          visible: _pendingVisible,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, left: 17.0, right: 25.0),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(AppLocalizations.of(context)!.immature, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0, color: Colors.white38)),
                              Expanded(
                                child: AutoSizeText("$_pending XDN",
                                    minFontSize: 8.0,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 14.0, color: Colors.white38)),
                              )
                            ]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 17.0, right: 25.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppLocalizations.of(context)!.st_headline, style: Theme.of(context).textTheme.headline5),
                              Expanded(
                                child: AutoSizeText(
                                  "${Utils.formatBalance(_stakeAmount)} XDN",
                                  minFontSize: 8.0,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 20.0),
                                ),
                              )
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                                  child: Divider(
                                    height: 1,
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0, bottom: 10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_lockedText, style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 14.0)),
                                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text(
                                          "${Utils.formatBalance(_locked)} XDN",
                                          style: Theme.of(context).textTheme.headline6!.copyWith(
                                                fontSize: 12.0,
                                              ),
                                        )
                                      ])
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppLocalizations.of(context)!.st_reward, style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 14.0)),
                                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text(
                                          "${Utils.formatBalance(_reward)} XDN",
                                          style: Theme.of(context).textTheme.headline6!.copyWith(
                                                fontSize: 12.0,
                                              ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                                  child: Divider(
                                    height: 1,
                                    color: Colors.white54,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Opacity(
                                  opacity: 0.7,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(AppLocalizations.of(context)!.st_total_coins, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0)),
                                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Text(
                                            "${Utils.formatBalance(_totalCoins).toString()} XDN",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                          ),
                                          // SizedBox(width: 35, height: 14, child: Text('XDN', textAlign: TextAlign.end, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),))
                                          // Container(width: 12, height: 12, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/logo_send.png'), fit: BoxFit.fitWidth))),
                                        ])
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Opacity(
                                  opacity: 0.7,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(AppLocalizations.of(context)!.st_contribution, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0)),
                                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Text(
                                            Utils.formatBalance(_contribution).toString(),
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Container(width: 12, height: 12, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/perc.png'), fit: BoxFit.fitWidth))),
                                        ])
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Opacity(
                                  opacity: 0.7,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: AutoSizeText(AppLocalizations.of(context)!.st_estimated,
                                              minFontSize: 8.0, maxLines: 1, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0)),
                                        ),
                                        Text(
                                          "${Utils.formatBalance(_estimated)} XDN",
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 15.0, right: 15.0),
                              child: Divider(
                                height: 1,
                                color: Colors.white12,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Flexible(
                                  child: Center(
                                child: FractionallySizedBox(
                                  widthFactor: 0.98,
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 9.0, right: 9.0),
                                    height: 50,
                                    child: AutoSizeTextField(
                                      controller: _controller,
                                      onChanged: (String text) async {
                                        // _searchUsers(text);
                                      },
                                      maxLines: 1,
                                      minFontSize: 5.0,
                                      keyboardType: Platform.isIOS ? const TextInputType.numberWithOptions(signed: true) : TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                                      ],
                                      textAlign: TextAlign.center,
                                      textAlignVertical: TextAlignVertical.center,
                                      cursorColor: Colors.white54,
                                      style: Theme.of(context).textTheme.headline5!.copyWith(fontStyle: FontStyle.normal, color: Colors.white),
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1.0), borderRadius: BorderRadius.circular(5.0)),
                                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.transparent, width: 1.0), borderRadius: BorderRadius.circular(5.0)),
                                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                                        filled: true,
                                        fillColor: const Color(0xFF1A1E2F),
                                        hoverColor: Colors.white60,
                                        focusColor: Colors.white60,
                                        isCollapsed: true,
                                        contentPadding: const EdgeInsets.only(bottom: 18.0, top: 10.0),
                                        labelStyle: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white),
                                        hintText: AppLocalizations.of(context)!.st_enter_amount,
                                        hintStyle: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, color: Colors.white30),
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                            ]),
                            const SizedBox(
                              height: 5.0,
                            ),
                            ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                              child: Container(
                                color: Colors.transparent,
                                child: PercentSwitchWidget(
                                  key: _percentageKey,
                                  changePercent: _changePercentage,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 5.0),
                              child: SlideAction(
                                sliderButtonIconPadding: 5.0,
                                sliderButtonIconSize: 20.0,
                                height: 50.0,
                                borderRadius: 5.0,
                                text: "${AppLocalizations.of(context)!.send_to} ${AppLocalizations.of(context)!.st_headline}",
                                innerColor: Colors.white.withOpacity(0.02),
                                outerColor: Colors.black.withOpacity(0.12),
                                elevation: 0.5,
                                // submittedIcon: const Icon(Icons.check, size: 30.0, color: Colors.lightGreenAccent,),
                                submittedIcon: const CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white70,
                                ),
                                sliderButtonIcon: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white70,
                                  size: 25.0,
                                ),
                                sliderRotate: false,
                                textStyle: const TextStyle(color: Colors.white24, fontSize: 24.0),
                                key: _keyStake,
                                onSubmit: () {
                                  _sendStakeCoins(_controller.text);
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Visibility(
                              visible: endTime == 0 ? true : false,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 15.0, right: 8.0),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.9,
                                    child: AutoSizeText(
                                      AppLocalizations.of(context)!.st_24h_lock,
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      minFontSize: 8,
                                      overflow: TextOverflow.fade,
                                      style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, color: Colors.white54),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Visibility(
                              visible: endTime == 0 ? false : true,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Center(
                                  child: AutoSizeText(AppLocalizations.of(context)!.st_time_until_unlock,
                                      style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 13.0, color: Colors.white70),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      minFontSize: 8,
                                      overflow: TextOverflow.fade),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: endTime == 0 ? false : true,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 5.0),
                                child: CountdownTimer(
                                  onEnd: () async {
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      setState(() {
                                        endTime = 0;
                                      });
                                    });
                                  },
                                  endTime: endTime,
                                  widgetBuilder: (_, CurrentRemainingTime? time) {
                                    if (time == null) {
                                      return const Text('');
                                    }
                                    return SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Center(
                                        child: Text('${_formatCountdownTime(time.hours ?? 0)}:${_formatCountdownTime(time.min?? 0)}:${_formatCountdownTime(time.sec ?? 0)}',
                                            style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 13.0, color: Colors.white70)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                      ],
                    ),
                  )),
                  Positioned.fill(
                      child: Visibility(
                        visible: _hideLoad ? false : true,
                        child: ClipRect(
                            child: Container(
                    margin: const EdgeInsets.only(left: 2.0, right: 2.0),
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                        border: Border.all(color: Theme.of(context).konjHeaderColor),
                        color: const Color(0xFF262C43),
                    ),
                    child: SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(
                            child: SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.white54,
                                  strokeWidth: 1.0,
                                ))),
                    ),
                  )),
                      )),
                ],
              ),
              const SizedBox(
                height: 10.0,
              ),
              Visibility(
                visible: _staking,
                child: Column(
                  children: [
                    ClipRect(
                      child: SizedBox(
                        height: 40,
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: TextButton(
                          onPressed: () {
                            _unstakeCoins(1);
                            // Dialogs.openUserQR(context);
                          },
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith((states) => getColor(states)),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0), side: BorderSide(color: Theme.of(context).konjHeaderColor)))),
                          child: Text(
                            AppLocalizations.of(context)!.st_withdraw_reward,
                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Visibility(
                      visible: endTime == 0 ? true : false,
                      child: ClipRect(
                        child: SizedBox(
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.95,
                          child: TextButton(
                            onPressed: () {
                              _unstakeCoins(0);
                              // Dialogs.openUserQR(context);
                            },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith((states) => getColorAll(states)),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.transparent)))),
                            child: Text(
                              AppLocalizations.of(context)!.st_withdraw_all,
                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  String _formatCountdownTime(int? time) {
    if (time == null || time == 0) {
      return "00";
    } else if (time < 10) {
      var s = time.toString();
      return '0$s';
    } else {
      return time.toString();
    }
  }

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {
    _paused = true;
  }

  @override
  void onResumed() {
    if (_paused) {
      _getBalance();
      _paused = false;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('_getBalanceFuture', _getBalanceFuture));
  }
}

Color getColor(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.white.withOpacity(0.8);
  }
  return const Color(0xff4d884f);
}

Color getColorAll(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.white.withOpacity(0.8);
  }
  return const Color(0xFFa85454);
}

Color qrColors(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.blue;
  }
  return const Color(0xff83a854);
}
