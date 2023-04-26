import 'dart:io';

import 'package:digitalnote/generated/phone.pb.dart';
import 'package:digitalnote/models/StakeData.dart';
import 'package:digitalnote/support/duration_extension.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class CoinStakeGraph extends StatefulWidget {
  final StakeGraphResponse? stake;
  final int type;
  final Function(bool touch) blockTouch;

  const CoinStakeGraph({Key? key, this.stake, required this.type, required this.blockTouch}) : super(key: key);

  @override
  CoinStakeGraphState createState() => CoinStakeGraphState();
}

class CoinStakeGraphState extends State<CoinStakeGraph> {
  double _leftTitlesInterval = 1;
  var _touch = false;
  StakeGraphResponse? _stakes;
  int _dropdownValue = 0;
  String? _date;
  String? _locale;

  final List<FlSpot> _values = [];

  double _minX = 0;
  double _maxX = 0;
  double _minY = 0;
  double _maxY = 0;

  final List<Color> _gradientColors = [
    const Color(0xFFFFFFFF).withOpacity(0.5),
    const Color(0xFFFFFFFF).withOpacity(0.3),
    const Color(0xFFFFFFFF).withOpacity(0.1),
    const Color(0xFFFFFFFF).withOpacity(0.0),
  ];

  // double _leftTitlesInterval = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _locale = Localizations.localeOf(context).languageCode;
    });
    _dropdownValue = widget.type;
    _stakes = widget.stake;
    _getDate();
    _prepareStakeData();
  }

  void _getDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    _date = formatter.format(now);
  }

  @override
  void dispose() {
    super.dispose();
  }

  DateTime _dateParse(String? day, int hour, int type) {
    if (type == 1 || type == 2) {
      return DateTime.parse(day!);
    }
    if (type == 3) {
      List<String> dt = day!.split("-");
      return DateTime(int.parse(dt[0]), int.parse(dt[1]));
    }
    var timeDifference = DateTime.now().timeZoneOffset.inHours;
    var datetime = DateTime.parse(day!);
    DateTime newTime = DateTime.now();
    if (timeDifference >= 0) {
      newTime = datetime.add(Duration(hours: hour));
    } else {
      newTime = datetime.add(Duration(hours: hour));
    }
    return newTime.toLocal();
  }

  void _prepareStakeData() async {
    try {
      List<StakeData>? data;
      if (_stakes != null) {
        var amount = 0.0;
        List<StakeData>? dataPrep = List.generate(_stakes!.rewards.length, (i) {
          return StakeData(
            date: _dateParse(_stakes!.rewards[i].day, _stakes!.rewards[i].hour, _dropdownValue),
            amount: _stakes!.rewards[i].amount,
          );
        });
        dataPrep.sort((a, b) => a.date.compareTo(b.date));
        data = List.generate(dataPrep.length, (i) {
          amount = amount + dataPrep[i].amount;
          return StakeData(
            date: dataPrep[i].date,
            amount: amount,
          );
        });
        if (_dropdownValue == 0) {
          _maxX = const Duration(minutes: 00, hours: 24).inMinutes.toDouble();
          // _leftTitlesInterval = (_maxY / 2);
          _minX = 0.0;
        } else if (_dropdownValue == 1) {
          _maxX = const Duration(days: 7).inDays.toDouble();
          // _leftTitlesInterval = (_maxY / 2);
          _minX = 0.0;
        } else if (_dropdownValue == 2) {
          _maxX = Duration(days: Jiffy.now().daysInMonth).inDays.toDouble();
          // _leftTitlesInterval = (_maxY / 2);
          _minX = 1.0;
        } else if (_dropdownValue == 3) {
          _maxX = 12.0;
          _minX = 0.0;
          // _leftTitlesInterval = (_maxY / 2);
        }
        _maxY = _getMaxY(data);
        _leftTitlesInterval = (_maxY / 2);
        _minY = 0.0;
      }

      if (data!.isNotEmpty) {
        List<FlSpot>? valuesData;
        if (_dropdownValue == 0) {
          valuesData = data
              .map((stakeData) {
                var d = Duration(minutes: 0, hours: stakeData.date.hour);
                return FlSpot(
                  d.inMinutes.toDouble(),
                  stakeData.amount,
                );
              })
              .cast<FlSpot>()
              .toList();
          _values.addAll(valuesData);
        } else if (_dropdownValue == 1) {
          List<StakeData> dt = [];
          var add = false;
          var subst = 0.0;
          var firstMon = data.first.date.weekday == 1 ? true : false;
          if (!firstMon) {
            for (var element in data) {
              if (element.date.weekday == 1) {
                add = true;
              }
              if (add) {
                var k = element.amount - subst;
                dt.add(StakeData(date: element.date, amount: k));
              } else {
                subst = element.amount;
              }
            }
          } else {
            dt.add(StakeData(date: data.last.date, amount: data.last.amount));
          }
          var i = 1;
          List<FlSpot> valuesData = dt
              .map((stakeData) {
                var d = Duration(days: i);
                i++;
                return FlSpot(
                  d.inDays.toDouble(),
                  stakeData.amount,
                );
              })
              .cast<FlSpot>()
              .toList();
          _values.addAll(valuesData);
        } else if (_dropdownValue == 2) {
          valuesData = data
              .map((stakeData) {
                var d = Duration(days: stakeData.date.day);
                return FlSpot(
                  d.inDays.toDouble(),
                  stakeData.amount,
                );
              })
              .cast<FlSpot>()
              .toList();
          _values.addAll(valuesData);
        } else if (_dropdownValue == 3) {
          valuesData = data
              .map((stakeData) {
                // var d = Duration(days: stakeData.date.month);
                return FlSpot(
                  stakeData.date.month.toDouble(),
                  stakeData.amount,
                );
              })
              .cast<FlSpot>()
              .toList();
          _values.addAll(valuesData);
        }
      } else {
        FlSpot firstSpot;
        _values.clear();
        if (_dropdownValue == 0) {
          firstSpot = const FlSpot(0, 0);
        } else {
          firstSpot = const FlSpot(1, 0);
        }

        if (data.isEmpty) {
          _values.add(firstSpot);
        }
      }
      setState(() {});
    } catch (e) {
      _values.clear();
      debugPrint(e.toString());
    }
  }

  double _getMaxY(List<StakeData>? l) {
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

  String _formatTooltip(double d) {
    try {
      var str = d.floorToDouble().toString();
      var split = str.split(".");
      var subs = split[1];
      var count = 0;
      loop:
      for (var i = 0; i < subs.length; i++) {
        if (subs[i] == "0") {
          count++;
        } else {
          break loop;
        }
      }
      if (count < 4) {
        return d.toStringAsFixed(2);
      }
      if (count > 8) {
        return d.toStringAsFixed(4);
      }
      return d.toString();
    } catch (e) {
      return "0.0";
    }
  }

  String _getMeTime(String? d, String format) {
    if (d == null) return "";
    String languageCode = Localizations.localeOf(context).languageCode;
    var date = DateTime.parse(d);
    String dateTime = DateFormat(format, languageCode).format(date);
    return dateTime;
  }

  String _getMeDate(String? d) {
    if (d == null) return "";
    var date = DateTime.parse(d);
    var format = DateFormat.yMd(Platform.localeName);
    return format.format(date);
  }

  // FlGridData _gridData() {
  //   return FlGridData(
  //     show: true,
  //     drawVerticalLine: true,
  //     drawHorizontalLine: true,
  //     getDrawingHorizontalLine: (value) {
  //       return FlLine(
  //         color: Colors.transparent,
  //         strokeWidth: 0.2,
  //       );
  //     },
  //     getDrawingVerticalLine: (value) {
  //       return FlLine(
  //         color: Colors.transparent,
  //         strokeWidth: 0.2,
  //       );
  //     },
  //     checkToShowHorizontalLine: (value) {
  //       return true;
  //     },
  //     checkToShowVerticalLine: (value) {
  //       return true;
  //     },
  //   );
  // }

  String _getToolTip(int time) {
    if (_dropdownValue == 0) {
      return '${_getMeTime("0000-00-00 ${Duration(minutes: time).toHoursMinutes()}", "HH:mm")}\n';
    } else if (_dropdownValue == 1) {
      DateTime date = DateTime.parse("1970-00-00");
      DateTime d = Jiffy.parseFromDateTime(date).add(days:  time).dateTime;
      return '${DateFormat.EEEE(_locale).format(d)}\n';
    } else if (_dropdownValue == 2) {
      List<String> dateParts = _date.toString().split("-");
      String tm = time < 10 ? "0$time" : time.toString();
      String dt = "${dateParts[0]}-${dateParts[1]}-$tm";
      return '${_getMeDate(dt)}\n';
    } else if (_dropdownValue == 3) {
      List<String> dateParts = _date.toString().split("-");
      String tm = time < 10 ? "0$time" : time.toString();
      String dt = "$tm/${dateParts[0]}";
      return '$dt\n';
    } else {
      return '${Duration(days: time * 31).inDays.toString()} \n';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<int> showIndexes = [_values.length - 1];
    final lineBarData = [
      LineChartBarData(
        spots: _values,
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

    LineChartData mainData() {
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
              LineBarSpot(lineBarData[0], 0, _values[index]),
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
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontStyle: FontStyle.normal, fontWeight: FontWeight.bold, fontSize: 14.0, color: Colors.white),
                          ),
                        ],
                      );
                    }).toList();
                  })));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 0.0, left: 0.0, top: 0, bottom: 0),
      child: _values.isEmpty
          ? Container(
              color: Colors.transparent,
              child: Center(
                  child: Padding(
                padding: const EdgeInsets.only(top: 200.0),
                child: Text(
                  AppLocalizations.of(context)!.graph_no_data,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white24),
                ),
              )),
            )
          : LineChart(
              mainData(),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.linearToEaseOut,
            ),
    );
  }

  String _getTime(String? d) {
    if (d == null) return "";
    var date = DateTime.parse(d);
    var format = DateFormat.jm(Platform.localeName);
    return format.format(date);
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
          String dd = _getTime("0000-00-00 $d");
          List<String> dateParts = dd.toString().split(" ");
          String finalDate = "";
          if (dateParts.length == 1) {
            finalDate = dd;
          } else {
            finalDate = dateParts[0] + dateParts[1];
          }
          text = finalDate;
        } else if (_dropdownValue == 2) {
          Duration d = Duration(days: value.toInt());
          text = d.inDays.toString();
        } else {
          Duration d = Duration(days: value.toInt());
          text = d.inDays.toString();
        }
        return Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white54, fontSize: 10.0),
        );
      },
      interval: _dropdownValue == 2 ? 4 : 300,
    ));
  }

  AxisTitles _leftTitles() {
    return AxisTitles(
        sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        return Text(
          _formatTitles(value.toInt()),
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white70, fontSize: 10.0),
        );
      },
      reservedSize: _dropdownValue == 0 ? 19 : 27,
      // margin: 7,
      interval: _leftTitlesInterval,
    ));
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
}
