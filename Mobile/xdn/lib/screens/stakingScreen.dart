import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:digitalnote/support/auto_size_text_field.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/card_header.dart';
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
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../globals.dart' as globals;
import '../support/ColorScheme.dart';
import '../support/Dialogs.dart';
import '../widgets/DropdownMenu.dart';
import '../support/Extensions.dart';
import '../support/LifecycleWatcherState.dart';
import '../support/NetInterface.dart';
import '../models/StakeData.dart';
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
  final _percentageKey = GlobalKey<PercentSwitchWidgetState>();
  final GlobalKey<SlideActionState> _keyStake = GlobalKey();
  final _controller = TextEditingController();
  StreamSubscription? _fcmSubscription;
  var _touch = false;
  var _liveVisible = 0;
  List<FlSpot>? values = [];

  double _minX = 0;
  double _maxX = 0;
  double _minY = 0;
  double _maxY = 0;
  double _leftTitlesInterval = 1;
  int endTime = 0;
  String _lockedText = '';
  int _serverStatus = 0;

  var _date = "0000-00-00";
  String _balance = "";
  String _imature = "";
  bool _staking = false;
  bool _paused = false;
  bool _imatureVisible = false;
  int _countNot = 0;
  bool _awaitingNot = false;
  double _totalCoins = 0.0;
  double _contribution = 0.0;
  double _estimated = 0.0;
  double _locked = 0.0;
  double _reward = 0.0;
  double _stakeAmount = 0.0;
  Timer? t;

  @override
  void initState() {
    super.initState();
    _getBalance();
    // _graphByDay();
    _checkCountdown();
    t = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      if (!_paused && mounted) {
        if (_dropdownValue == 0) {
          _getBalance();
          _graphByDay();
        }
      } else {
        t.cancel();
      }
    });
    _controller.addListener(() {
      _percentageKey.currentState!.deActivate();
    });

    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      _not();
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
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
    t!.cancel();
    _fcmSubscription!.cancel();
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
    Future.delayed(const Duration(milliseconds: 4000), () {
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

  void _graphByDay() async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    _date = formatter.format(now);
    var res = await NetInterface.getRewardsByDay(context, _date, 0);
    if (res == null) return;
    List<StakeData> d = await compute(_getData, res);
    d.sort(((a, b) => a.date.compareTo(b.date)));

    _maxX = const Duration(minutes: 00, hours: 24).inMinutes.toDouble();
    _maxY = await compute(_getMaxY, d);
    _leftTitlesInterval = (_maxY / 2);
    _minX = 0;
    _minY = 0;
    _liveVisible = 1;
    _prepareStakeData(d);
  }

  void _graphByMonth() async {
    _liveVisible = 0;
    final DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString();

    var res = await NetInterface.getRewardsByMonth(context, year, month, 1);
    if (res == null) return;
    List<StakeData> d = await compute(_getDataMonth, res);
    _maxX = Duration(days: Jiffy().daysInMonth).inDays.toDouble();
    _maxY = await compute(_getMaxY, d);
    _leftTitlesInterval = (_maxY / 2);
    _minX = 1;
    _minY = 0;
    _prepareStakeData(d);
  }

  static List<StakeData> _getData(String response) {
    try {
      List responseList = json.decode(response);
      responseList.removeAt(0);
      responseList.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
      var amount = 0.0;
      var l = List.generate(responseList.length, (i) {
        amount = amount + responseList[i]['amount'];
        return StakeData(
          date: DateTime.parse(responseList[i]['date']),
          amount: amount,
        );
      });
      return l;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return [];
    }
  }

  static List<StakeData> _getDataMonth(String response) {
    try {
      List responseList = json.decode(response);
      var amount = 0.0;
      var l = List.generate(responseList.length, (i) {
        amount = amount + responseList[i]['amount'];
        return StakeData(
          date: DateTime.parse(responseList[i]['date']),
          amount: amount,
        );
      });
      return l;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return [];
    }
  }

  static double _getMaxY(List<StakeData>? l) {
    double max = 0;
    try {
      if (l == null) return 0;
      for (var element in l) {
        if (element.amount > max) max = element.amount;
      }
      if (max < 10) {
        return 10;
      } else if (max < 50) {
        return 50;
      } else if (max < 100) {
        return 100;
      } else if (max < 1000) {
        return 1000;
      } else if (max < 10000) {
        return 10000;
      } else if (max < 100000) {
        return 100000;
      } else {
        return max;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return max;
  }

  void _getBalance() async {
    _getBalanceFuture = NetInterface.getBalance(details: true);
    if (_dropdownValue == 0) {
      _graphByDay();
    } else {
      _graphByMonth();
    }
    await _checkPoolStats();
    await _checkStaking();
  }

  Future<void> _checkStaking() async {
    if (_locked == 0.0) {
      setState(() {
        _staking = false;
      });
      // animationStakeController!.reverse();
    } else {
      setState(() {
        _staking = true;
      });
    }
    _lockedText = AppLocalizations.of(context)!.st_locked_coins;
  }

  Future<void> _checkPoolStats() async {
    var s = await NetInterface.getPoolStats(context);
    if (s == null) {
      return;
    }
    setState(() {
      _totalCoins = double.parse(s["total"].toString());
      _contribution = _dp(double.parse(s["contribution"].toString()), 2);
      _estimated = double.parse(s["estimated"].toString());
      _locked = _dp(double.parse(s["locked"].toString()), 2);
      _reward = _dp(double.parse(s["reward"].toString()), 2);
      _stakeAmount = _dp(double.parse(s["amount"].toString()), 2);
    });
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
          endTime = int.parse(countDown);
        });
      } else {
        setState(() {
          _lockedText = AppLocalizations.of(context)!.st_coins_staked;
        });
      }
    }
  }

  void _prepareStakeData(List<StakeData>? data) async {
    FlSpot firstSpot;
    values!.clear();
    if (_dropdownValue == 0) {
      firstSpot = const FlSpot(0, 0);
    } else {
      firstSpot = const FlSpot(1, 0);
    }

    if (data!.isEmpty) {
      values!.add(firstSpot);
    }

    if (data.isNotEmpty) {
      List<FlSpot>? valuesData;
      valuesData = data
          .map((stakeData) {
            if (_dropdownValue == 0) {
              var hours = Jiffy(stakeData.date).hour;
              var minutes = Jiffy(stakeData.date).minute;
              var d = Duration(minutes: minutes, hours: hours);
              return FlSpot(
                d.inMinutes.toDouble(),
                stakeData.amount,
              );
            } else if (_dropdownValue == 1) {
              var d = Duration(days: stakeData.date.day);
              return FlSpot(
                d.inDays.toDouble(),
                stakeData.amount,
              );
            }
          })
          .cast<FlSpot>()
          .toList();

      values!.addAll(valuesData);
    }

    try {
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<int> showIndexes = [values!.length - 1];
    final lineBarData = [
      LineChartBarData(
        spots: values,
        showingIndicators: showIndexes,
        color: Colors.white70,
        barWidth: 1.2,
        isStrokeCapRound: true,
        isCurved: true,
        curveSmoothness: 0.25,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: _gradientColors,
              stops: const [0, 0.5, 0.7, 0.95],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )),
      ),
    ];

    LineChartData _mainData() {
      return LineChartData(
          gridData: _gridData(),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: _maxY / 2,
              color: Colors.white30,
              strokeWidth: 0.2,
            ),
          ]),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles()),
            rightTitles: AxisTitles(sideTitles: SideTitles()),
            bottomTitles: _bottomTitles(),
            leftTitles: _leftTitles(),
          ),
          borderData: FlBorderData(
            border: const Border(bottom: BorderSide(color: Colors.white30, width: 0.5), left: BorderSide(color: Colors.white30, width: 0.5)),
          ),
          minX: _minX,
          maxX: _maxX,
          minY: _minY,
          maxY: _maxY,
          showingTooltipIndicators: showIndexes.map((index) {
            return ShowingTooltipIndicators([
              LineBarSpot(lineBarData[0], 0, values![index]),
            ]);
          }).toList(),
          lineBarsData: lineBarData,
          lineTouchData: LineTouchData(
              touchCallback: (FlTouchEvent? event, LineTouchResponse? touchResponse) {
                if (event is FlTapDownEvent || event is FlPointerHoverEvent || event is FlPanDownEvent) {
                  setState(() {
                    _touch = true;
                  });
                } else if (event is FlLongPressEnd || event is FlTapUpEvent) {
                  setState(() {
                    _touch = false;
                  });
                } else if (event is FlTapCancelEvent) {
                  setState(() {
                    _touch = false;
                  });
                } else if (event is FlPanStartEvent || event is FlLongPressMoveUpdate) {
                  setState(() {
                    _touch = true;
                  });
                } else if (event is FlPanEndEvent || event is FlPanCancelEvent) {
                  setState(() {
                    _touch = false;
                  });
                }
              },
              enabled: _touch,
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(color: Colors.white54, strokeWidth: 0.8),
                    FlDotData(
                        show: true,
                        getDotPainter: (FlSpot spot, double radius, LineChartBarData lc, int i) {
                          return FlDotCirclePainter(color: const Color(0xFF312d53).withOpacity(0.5), strokeColor: Colors.white54, radius: 3.0);
                        }),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 5,
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  tooltipBgColor: Colors.black12,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final flSpot = barSpot;

                      return LineTooltipItem(
                        // Duration d =  value.toInt());
                        _getToolTip(flSpot.x.toInt()),
                        // '${Duration(minutes: flSpot.x.toInt()).toHoursMinutes().toString()} \n',
                        GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.w400, fontSize: 12),
                        children: [
                          TextSpan(
                            text: "${flSpot.y.toStringAsFixed(3)} XDN",
                            style: Theme.of(context)
                                .textTheme
                                .headline5!
                                .copyWith(fontStyle: FontStyle.normal, fontWeight: FontWeight.bold, fontSize: 14.0, color: Colors.white),
                          ),
                        ],
                      );
                    }).toList();
                  })));
    }

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
                    decoration: BoxDecoration(
                        color: const Color(0xFF262C43),
                        border: Border.all(color: Colors.transparent),
                        borderRadius: const BorderRadius.all(Radius.circular(10.0))),
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
                              values!.clear();
                              setState(() {});
                              switch (index) {
                                case 0:
                                  _graphByDay();
                                  break;
                                case 1:
                                  _graphByMonth();
                                  break;
                                case 2:
                                  // _graphByYear();
                                  break;
                              }
                              _dropdownValue = index;
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
                                      child: Text(item.value,
                                          style: Theme.of(context).textTheme.button!.copyWith(fontSize: 16.0, color: Colors.white70)),
                                    ),
                                  ),
                                )
                                .toList(),
                            child: const Text(
                              'dropdown',
                            ),
                          ),
                        ),

                        // Divider(height: 2.0,color: Colors.white38,),
                        Stack(
                          children: [
                            AnimatedOpacity(
                              opacity: _liveVisible == 1 ? 1 : 0,
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(right: 35.0, top: 5.0),
                                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.8),
                                    child: AvatarGlow(
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
                                  ),
                                  const SizedBox(
                                    width: 2.0,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.st_live.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5!
                                        .copyWith(fontSize: 8.0, fontWeight: FontWeight.w300, color: Colors.white54),
                                  ),
                                ]),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 5),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.2,
                                  width: MediaQuery.of(context).size.width * 0.92,
                                  child: values!.isEmpty
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white70,
                                            strokeWidth: 3.0,
                                          ),
                                        )
                                      : LineChart(
                                          _mainData(),
                                          swapAnimationDuration: const Duration(milliseconds: 500),
                                          swapAnimationCurve: Curves.linearToEaseOut,
                                        ),
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
              Padding(
                  padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                  child: ClipRect(
                      child: Container(
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
                                child: AutoSizeText(
                                    AppLocalizations.of(context)!.available,
                                    maxLines: 1,
                                    minFontSize: 8.0,
                                    style: Theme.of(context).textTheme.headline5),
                              ),
                              FutureBuilder(
                                  future: _getBalanceFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      Map m = snapshot.data as Map<String, dynamic>;
                                      _balance = double.parse(m['spendable'].toString()).toStringAsFixed(3);
                                      _imature = m['immature'].toString();
                                      t = Timer(const Duration(milliseconds: 100), () {
                                        setState(() {
                                          _imatureVisible = _imature == "0.000" ? false : true;
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
                                                backgroundColor: Colors.black45,
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
                              Text(AppLocalizations.of(context)!.immature,
                                  style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0, color: Colors.white38)),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 17.0, right: 25.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppLocalizations.of(context)!.st_headline, style: Theme.of(context).textTheme.headline5),
                              Expanded(
                                child: AutoSizeText(
                                  "$_stakeAmount XDN",
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
                            Visibility(
                              visible: _staking,
                              child: Column(
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
                                            "$_locked XDN",
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
                                        Text(AppLocalizations.of(context)!.st_reward,
                                            style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 14.0)),
                                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Text(
                                            "$_reward XDN",
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
                                          Text(AppLocalizations.of(context)!.st_total_coins,
                                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0)),
                                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                            Text(
                                              "${_totalCoins.toString()} XDN",
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
                                          Text(AppLocalizations.of(context)!.st_contribution,
                                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0)),
                                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                            Text(
                                              _contribution.toString(),
                                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Container(
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                    image: DecorationImage(image: AssetImage('images/perc.png'), fit: BoxFit.fitWidth))),
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
                                                minFontSize: 8.0,
                                                maxLines: 1,
                                                style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0)),
                                          ),
                                          Text(
                                            "${_estimated.toString()} XDN",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                                        focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(color: Colors.white30, width: 1.0),
                                            borderRadius: BorderRadius.circular(5.0)),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(color: Colors.transparent, width: 1.0),
                                            borderRadius: BorderRadius.circular(5.0)),
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
                                        child: Text(
                                            '${_formatCountdownTime(time.hours!)}:${_formatCountdownTime(time.min!)}:${_formatCountdownTime(time.sec!)}',
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
                  ))),
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
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), side: BorderSide(color: Theme.of(context).konjHeaderColor)))),
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
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.transparent)))),
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

  // final tooltipsOnBar = _values[0];
  String _getMeDate(String? d) {
    if (d == null) return "";
    var date = DateTime.parse(d);
    var format = DateFormat.yMd(Platform.localeName);
    return format.format(date);
  }

  String _getMeTime(String? d) {
    if (d == null) return "";
    var date = DateTime.parse(d);
    var format = DateFormat.jm(Platform.localeName);
    return format.format(date);
  }

  String _getToolTip(int time) {
    if (_dropdownValue == 0) {
      return '${_getMeTime("0000-00-00 ${Duration(minutes: time).toHoursMinutes()}")}\n';
    } else if (_dropdownValue == 1) {
      List<String> dateParts = _date.toString().split("-");
      String tm = time < 10 ? "0$time" : time.toString();
      String dt = "${dateParts[0]}-${dateParts[1]}-$tm";
      return '${_getMeDate(dt)}\n';
    } else {
      return '${Duration(days: time * 31).inDays.toString()} \n';
    }
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

  final List<Color> _gradientColors = [
    const Color(0xFFFFFFFF).withOpacity(0.5),
    const Color(0xFFFFFFFF).withOpacity(0.3),
    const Color(0xFFFFFFFF).withOpacity(0.1),
    const Color(0xFFFFFFFF).withOpacity(0.0),
  ];

  AxisTitles _leftTitles() {
    return AxisTitles(
        sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        return Text(
          _formatTitles(value.toInt()),
          style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white70, fontSize: 10.0),
        );
      },
      reservedSize: _dropdownValue == 0 ? 19 : 27,
      // margin: 7,
      interval: _leftTitlesInterval,
    ));
  }

  AxisTitles _bottomTitles() {
    return AxisTitles(
        sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 20.0,
      getTitlesWidget: (value, meta) {
        var text = "";
        if (_dropdownValue == 0) {
          String d = Duration(minutes: value.toInt()).toHoursMinutes();
          String dd = _getMeTime("0000-00-00 $d");
          List<String> dateParts = dd.toString().split(" ");
          String finalDate = "";
          if (dateParts.length == 1) {
            finalDate = dd;
          } else {
            finalDate = dateParts[0] + dateParts[1];
          }
          text = finalDate;
        } else if (_dropdownValue == 1) {
          Duration d = Duration(days: value.toInt());
          text = d.inDays.toString();
        } else {
          Duration d = Duration(days: value.toInt());
          text = d.inDays.toString();
        }
        return Text(
          text,
          style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white54, fontSize: 10.0),
        );
      },
      interval: _dropdownValue == 1 ? 3 : 300,
    ));
  }

  FlGridData _gridData() {
    return FlGridData(
      show: false,
      drawVerticalLine: true,
      drawHorizontalLine: true,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.white12,
          strokeWidth: 0.2,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: Colors.white12,
          strokeWidth: 0.2,
        );
      },
      checkToShowHorizontalLine: (value) {
        return true;
      },
      checkToShowVerticalLine: (value) {
        return true;
      },
    );
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

  String _formatTitles(int i) {
    if (i >= 1000) {
      return "${(i / 1000).round()}k";
    } else if (i >= 500) {
      return "${i / 1000}k";
    } else {
      return i.toString();
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
