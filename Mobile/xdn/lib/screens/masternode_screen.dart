import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:digitalnote/bloc/masternode_graph_bloc.dart';
import 'package:digitalnote/generated/phone.pb.dart';
import 'package:digitalnote/models/MasternodeInfo.dart';
import 'package:digitalnote/models/MasternodeLock.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/net_interface/app_exception.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/mn_manage_screen.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/coin_mn_graph.dart';
import 'package:digitalnote/widgets/coin_stake_graph.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../support/ColorScheme.dart';
import '../support/Dialogs.dart';
import '../support/LifecycleWatcherState.dart';
import '../support/NetInterface.dart';
import '../widgets/DropdownMenu.dart';
import '../widgets/backgroundWidget.dart';

class MasternodeScreen extends StatefulWidget {
  static const String route = "menu/masternode";

  const MasternodeScreen({Key? key}) : super(key: key);

  @override
  MasternodeScreenState createState() => MasternodeScreenState();
}

class MasternodeScreenState extends LifecycleWatcherState<MasternodeScreen> {
  var _dropdownValue = 0;
  Future? _getBalanceFuture;
  final _graphKey = GlobalKey<CoinStakeGraphState>();
  final GlobalKey<SlideActionState> _keyStake = GlobalKey();
  StreamSubscription? _fcmSubscription;
  MasternodeGraphBloc? _stakeBloc;
  List<FlSpot>? values = [];

  int endTime = 0;

  MasternodeInfo? _mnInfo;
  String _balance = "";
  String _imature = "";
  String _pending = "";
  bool _staking = false;
  bool _paused = false;
  bool _imatureVisible = false;
  bool _pendingVisible = false;
  bool _hideLoad = false;
  bool _loadingReward = false;
  bool _loadingCoins = false;
  int _countNot = 0;
  bool _awaitingNot = false;
  double _estimated = 0.0;
  Timer? t;
  int _typeGraph = 0;

  int _numberNodes = 0;
  int _freeMN = 0;
  int _pendingMasternodes = 0;
  String _amountReward = "0.0";
  int _activeNodes = 0;

  // String _averagePayrate = "00:00:00";
  String _averateTimeStart = "00:00:00";
  double _averagePayDay = 0.0;
  double _roi = 0.0;

  // double _price = 0.0;
  // double _free = 0.0;
  // List<int> _collateralTiers = [];

  double? _fee;
  double? _min;
  bool amountEmpty = true;
  int _collateral = 0;

  @override
  void initState() {
    super.initState();
    _getBalance();
    t = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      if (!_paused && mounted) {
        if (_dropdownValue == 0) {
          _getBalance();
          _stakeBloc!.fetchStakeData(0, _dropdownValue);
          // _graphByDay();
        }
      } else {
        t.cancel();
      }
    });

    _stakeBloc = MasternodeGraphBloc();
    _stakeBloc!.stakeBloc();
    _stakeBloc!.fetchStakeData(0, _typeGraph);

    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _not();
      if (message.notification != null) {
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

  void _getBalance() async {
    _getBalanceFuture = NetInterface.getBalance(details: true);
    setState(() {});
    await _getMasternodeDetails();
  }

  Future<void> _getMasternodeDetails() async {
    ComInterface interface = ComInterface();
    var res = await interface.get("/masternode/info", debug: false, serverType: ComInterface.serverGoAPI, request: {});
    _mnInfo = MasternodeInfo.fromJson(res);
    if (_mnInfo == null || _mnInfo!.hasError == true) return;
    _numberNodes = _mnInfo?.mnList?.length ?? 0;
    _activeNodes = _mnInfo!.activeNodes!;
    double rev = _mnInfo!.nodeRewards!.fold(0, (previousValue, element) => previousValue + element.amount!);
    _amountReward = rev.toString();
    List<String> partsStart = _mnInfo!.averageTimeToStart!.split(".");
    _averateTimeStart = partsStart[0].isEmpty ? "00:00:00" : partsStart[0];
    _estimated = _mnInfo!.averageRewardPerDay!;
    _staking = _mnInfo!.mnList!.isNotEmpty ? true : false;
    _collateral = _mnInfo!.collateral!;
    _averagePayDay = _mnInfo!.averagePayDay!;
    _freeMN = _mnInfo?.freeList?.length ?? 0;
    _pendingMasternodes = _mnInfo?.pendingList?.length ?? 0;
    // _collateralTiers = _mnInfo?.collateralTiers ?? [_collateral];
    _roi = _mnInfo?.roi ?? 0.0;
    _hideLoad = true;
    setState(() {});
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
                header: "Masternode".toUpperCase(),
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
                                  _stakeBloc!.fetchStakeData(0, _dropdownValue);
                                  // _graphByDay();
                                  break;
                                case 1:
                                  _typeGraph = 2;
                                  _stakeBloc!.fetchStakeData(0, _typeGraph);
                                  // _graphByMonth();
                                  break;
                                case 2:
                                  _typeGraph = 3;
                                  _stakeBloc!.fetchStakeData(0, _typeGraph);
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
                              AppLocalizations.of(context)!.mn_coins_year,
                            ]
                                .asMap()
                                .entries
                                .map(
                                  (item) => DropdownItem<int>(
                                    value: item.key + 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(item.value, style: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 16.0, color: Colors.white70)),
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
                                        child: StreamBuilder<ApiResponse<MasternodeGraphResponse>>(
                                            stream: _stakeBloc!.coinsListStream,
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                switch (snapshot.data!.status) {
                                                  case Status.completed:
                                                    return CoinMNGraph(
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
                                                            style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red),
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
                                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 8.0, fontWeight: FontWeight.w300, color: Colors.white54),
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
                                child: AutoSizeText(AppLocalizations.of(context)!.available, maxLines: 1, minFontSize: 8.0, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 16.0, color: Colors.white70)),
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
                                          "${Utils.formatBalance(double.parse(_balance))} XDN",
                                          minFontSize: 8.0,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          textAlign: TextAlign.right,
                                          style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16.0),
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                        snapshot.error.toString(),
                                        style: GoogleFonts.montserrat(fontStyle: FontStyle.normal, fontSize: 12, color: Colors.red),
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
                              Text(AppLocalizations.of(context)!.immature, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 14.0, color: Colors.white38)),
                              Expanded(
                                child: AutoSizeText("$_imature XDN",
                                    minFontSize: 8.0,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 14.0, color: Colors.white38)),
                              )
                            ]),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Visibility(
                          visible: _pendingVisible,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, left: 17.0, right: 25.0),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(AppLocalizations.of(context)!.immature, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 14.0, color: Colors.white38)),
                              Expanded(
                                child: AutoSizeText("$_pending XDN",
                                    minFontSize: 8.0,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 14.0, color: Colors.white38)),
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
                              Text(AppLocalizations.of(context)!.mn_collateral, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 16.0, color: Colors.white70)),
                              Expanded(
                                child: AutoSizeText(
                                  "${Utils.formatBalance(_collateral.toDouble())} XDN",
                                  minFontSize: 8.0,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16.0),
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
                                    children: [
                                      Text(
                                        "${AppLocalizations.of(context)!.mn_your_mns}:",
                                        // textAlign: TextAlign.end,
                                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0, color: Colors.white.withOpacity(0.4)),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 4.0),
                                          child: AutoSizeText(
                                            _numberNodes.toString(),
                                            maxLines: 1,
                                            minFontSize: 8.0,
                                            textAlign: TextAlign.end,
                                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white70),
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        "MNs",
                                        // textAlign: TextAlign.end,
                                        style: TextStyle(fontFamily: 'JosefinSans', fontWeight: FontWeight.w600, fontSize: 14.0, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_numberNodes > 0 || _pendingMasternodes > 0)
                                  Column(
                                    children: [
                                      if (_pendingMasternodes != 0)
                                        Column(
                                          children: [
                                            Column(
                                              children: [
                                                Opacity(
                                                  opacity: 0.6,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0, bottom: 10.0),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "${AppLocalizations.of(context)!.mn_uncofirmed}:",
                                                          // textAlign: TextAlign.end,
                                                          style: TextStyle(fontFamily: 'JosefinSans', fontWeight: FontWeight.w500, fontSize: 12.0, color: Colors.white.withOpacity(0.4)),
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding: const EdgeInsets.only(right: 4.0),
                                                            child: AutoSizeText(
                                                              _pendingMasternodes.toString(),
                                                              maxLines: 1,
                                                              minFontSize: 8.0,
                                                              textAlign: TextAlign.end,
                                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12.0, color: Colors.white70),
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          _pendingMasternodes == 1 ? "MN" : "MNs",
                                                          // textAlign: TextAlign.end,
                                                          style: const TextStyle(fontFamily: 'JosefinSans', fontWeight: FontWeight.w600, fontSize: 12.0, color: Colors.white70),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0, bottom: 10.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              "${AppLocalizations.of(context)!.mn_reward}:",
                                              // textAlign: TextAlign.end,
                                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0, color: Colors.white.withOpacity(0.4)),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 4.0),
                                                child: AutoSizeText(
                                                  _formatPriceString(_amountReward),
                                                  maxLines: 1,
                                                  minFontSize: 8.0,
                                                  textAlign: TextAlign.end,
                                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white70),
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              "XDN",
                                              // textAlign: TextAlign.end,
                                              style: TextStyle(fontFamily: 'JosefinSans', fontWeight: FontWeight.w600, fontSize: 14.0, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0, bottom: 10.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              "${AppLocalizations.of(context)!.st_estimated}:",
                                              // textAlign: TextAlign.end,
                                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0, color: Colors.white.withOpacity(0.4)),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 4.0),
                                                child: AutoSizeText(
                                                  Utils.formatBalance(_estimated),
                                                  maxLines: 1,
                                                  minFontSize: 8.0,
                                                  textAlign: TextAlign.end,
                                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0, color: Colors.white70),
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              "XDN",
                                              // textAlign: TextAlign.end,
                                              style: TextStyle(fontFamily: 'JosefinSans', fontWeight: FontWeight.w600, fontSize: 14.0, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
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
                                        Text("${AppLocalizations.of(context)!.all_mn("XDN")}:", style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0)),
                                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Text(
                                            "$_activeNodes",
                                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0),
                                          ),
                                          // SizedBox(width: 35, height: 14, child: Text('XDN', textAlign: TextAlign.end, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0),))
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
                                        Text(AppLocalizations.of(context)!.mn_free, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0)),
                                        Text(
                                          _freeMN.toString(),
                                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Visibility(
                                  visible: _activeNodes == 0,
                                  child: Column(
                                    children: [
                                      Opacity(
                                        opacity: 0.7,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: AutoSizeText(AppLocalizations.of(context)!.mn_day_reward,
                                                    minFontSize: 8.0, maxLines: 1, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0)),
                                              ),
                                              Text(
                                                "${Utils.formatBalance(_averagePayDay)} XDN",
                                                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Opacity(
                                  opacity: 0.7,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 0, left: 17.0, right: 25.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: AutoSizeText("APY", minFontSize: 8.0, maxLines: 1, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0)),
                                        ),
                                        Text(
                                          "${_roi.toStringAsFixed(2)} %",
                                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0),
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
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 5.0),
                              child: SlideAction(
                                sliderButtonIconPadding: 5.0,
                                sliderButtonIconSize: 20.0,
                                height: 50.0,
                                borderRadius: 5.0,
                                text: AppLocalizations.of(context)!.mn_start,
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
                                  _createWithdrawal();
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: AutoSizeText(
                                  "${AppLocalizations.of(context)!.mn_time_to_start}  | $_averateTimeStart",
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  minFontSize: 8,
                                  overflow: TextOverflow.fade,
                                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 10.0, color: Colors.white54),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: AutoSizeText(
                                  AppLocalizations.of(context)!.mn_lock,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  minFontSize: 8,
                                  overflow: TextOverflow.fade,
                                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 12.0, color: Colors.white54),
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
                                  child: AutoSizeText(AppLocalizations.of(context)!.mn_lock,
                                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 13.0, color: Colors.white70),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      minFontSize: 8,
                                      overflow: TextOverflow.fade),
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
                visible: _staking && _amountReward != "0.0",
                child: Column(
                  children: [
                    ClipRect(
                      child: SizedBox(
                        height: 40,
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: TextButton(
                          onPressed: () {
                            _unStake(1);
                            // Dialogs.openUserQR(context);
                          },
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith((states) => getColor(states)),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0), side: BorderSide(color: Theme.of(context).konjHeaderColor)))),
                          child: Text(
                            AppLocalizations.of(context)!.mn_withdraw_reward,
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _staking,
                child: ClipRect(
                  child: SizedBox(
                    height: 40,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, MasternodeManageScreen.route, arguments: _mnInfo);
                        // Dialogs.openUserQR(context);
                      },
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith((states) => getColorAll(states)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.transparent)))),
                      child: Text(
                        AppLocalizations.of(context)!.mn_manage,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  _createWithdrawal() async {
    Dialogs.openWaitBox(context);

    if (_mnInfo == null) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "Data error");
      _keyStake.currentState?.reset();
      return;
    }

    var amt = _collateral;

    if (amt > (double.parse(_balance) + 0.01)) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.dl_not_enough_coins);
      _keyStake.currentState?.reset();
      return;
    }

    try {
      await _getMasternodeDetails();
    } catch (e) {
      debugPrint(e.toString());
    }
    MasternodeLock? mnLock;
    try {
      ComInterface interface = ComInterface();
      Map<String, dynamic> queryLock = {"idCoin": 0};
      final responseLock = await interface.post("/masternode/lock", body: queryLock, serverType: ComInterface.serverGoAPI, debug: true);
      mnLock = MasternodeLock.fromJson(responseLock);
      if (mnLock.node?.address == null) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "Data err");
        _keyStake.currentState?.reset();
        return;
      }
      if (mnLock.node?.id == null) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "Node err");
        _keyStake.currentState?.reset();
        return;
      }
      await interface.post("/masternode/start", body: {"idCoin": 0, "node_id": mnLock.node!.id!}, serverType: ComInterface.serverGoAPI, debug: true);
      _getBalance();
      if (mounted) Navigator.of(context).pop();
      _keyStake.currentState?.reset();
    } catch (e) {
      ComInterface interface = ComInterface();
      Map<String, dynamic> queryLock = {"idNode": mnLock?.node?.id};
      await interface.post("/masternode/unlock", body: queryLock, serverType: ComInterface.serverGoAPI, debug: true);
      if (mounted) Navigator.of(context).pop();
      _keyStake.currentState?.reset();
      var err = json.decode(e.toString());
      if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, err['errorMessage'].toString());
    }
  }

  _unStake(int rewardParam) async {
    final interface = ComInterface();
    if (_loadingReward || _loadingCoins) {
      return;
    }
    Dialogs.openWaitBox(context);
    if (rewardParam == 1) {
      _loadingReward = true;
    } else {
      _loadingCoins = true;
    }
    setState(() {});
    try {
      if (rewardParam == 1) {
        Map<String, dynamic> m = {"idCoin": 0};
        await interface.post("/masternode/reward", body: m, serverType: ComInterface.serverGoAPI, debug: true);
      }

      _getBalance();
      if (rewardParam == 1) {
        _loadingReward = false;
      } else {
        _loadingCoins = false;
      }
      await _getMasternodeDetails();
      setState(() {});
      if (mounted) {
        Navigator.of(context).pop();
        await _getMasternodeDetails();
      }
    } on ConflictDataException catch (e) {
      var err = json.decode(e.toString());
      if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, err['errorMessage'].toString());
    } catch (e) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, e.toString());
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
  return Colors.blueAccent;
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
