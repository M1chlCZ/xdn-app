import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class DataBar extends StatefulWidget {
  final String title;
  final double percentage;
  final double amount;
  final int goal;
  final double? userPercentage;
  final double? userAmount;
  final int index;
  final String address;
  final int idEntry;
  final Function(String addr, int idEntry) callBack;

  const DataBar(
      {Key? key,
      required this.title,
      required this.percentage,
      this.userPercentage,
      required this.amount,
      this.userAmount,
      required this.index,
      required this.address,
      required this.callBack,
      required this.idEntry,
      required this.goal})
      : super(key: key);

  @override
  State<DataBar> createState() => _DataBarState();
}

class _DataBarState extends State<DataBar> with TickerProviderStateMixin {
  double size = 0.0;
  double? userSize;

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() {
    if (widget.userPercentage != null) {
      setState(() {
        userSize = 0.0;
      });
    }
    Future.delayed(const Duration(milliseconds: (250)), () {
      setState(() {
        size = widget.percentage;
      });
    });
    Future.delayed(const Duration(milliseconds: (350)), () {
      setState(() {
        userSize = widget.userPercentage;
      });
    });
  }

  _update() {
    if (widget.userPercentage != null) {
      userSize = 0.0;
    }
    size = widget.percentage;
    userSize = widget.userPercentage;
    setState(() {});
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount || oldWidget.userAmount != widget.userAmount) {
      _update();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onTap: () {
              widget.callBack(widget.address, widget.idEntry);
            },
            splashColor: Colors.white30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1), // changes position of shadow
                    ),
                  ],
                ),
                child: LayoutBuilder(builder: (context, constrains) {
                  var width = constrains.maxWidth;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.amount.toInt()}',
                                    style: Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white70),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  stops: const [0.6, 1.0],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: widget.index == 0 && widget.amount != 0
                                      ? [Colors.amber, Colors.amber.shade600]
                                      : [
                                          Colors.blue,
                                          Colors.blue.shade600,
                                        ]),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.index == 0 && widget.amount != 0 ? const Color(0x74FFC109) : const Color(0xFF0E61AB),
                                  blurRadius: 1.2,
                                  spreadRadius: 1.2,
                                  offset: const Offset(0, 1),
                                ),
                                BoxShadow(
                                  color: widget.index == 0 && widget.amount != 0 ? const Color(0xFFFFC509) : const Color(0xFF0E61AB),
                                  blurRadius: 0.1,
                                  spreadRadius: 0.2,
                                  offset: const Offset(1, 0),
                                ),
                              ],
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                            ),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.elasticOut,
                              child: SizedBox(
                                height: 25,
                                width: width * size,
                                child: width * widget.percentage > width * 0.1
                                    ? Row(children: [
                                        const Expanded(child: SizedBox()),
                                        AutoSizeText(
                                          widget.amount.toInt().toString(),
                                          maxLines: 1,
                                          minFontSize: 0.1,
                                          stepGranularity: 0.1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge!
                                              .copyWith(color: widget.index == 0 ? Colors.black.withOpacity(0.4) : Colors.white54, fontSize: 12, fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        )
                                      ])
                                    : Container(),
                              ),
                            ),
                          ),
                          // SizedBox(
                          //   height: userSize == 0.0 ? 20 : 5,
                          // ),
                          // if (userSize != 0.0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 0.5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      stops: const [0.6, 1.0],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.green,
                                        Colors.green.shade600,
                                      ]),
                                  boxShadow: _getShadow(userSize!),
                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                                ),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.bounceOut,
                                  child: SizedBox(
                                    height: 24,
                                    width: (width * widget.percentage) * userSize!,
                                    child: widget.userAmount != null && ((width * widget.percentage) * widget.userPercentage!) > width * 0.1
                                        ? Row(children: [
                                            const Expanded(child: SizedBox()),
                                            AutoSizeText(
                                              widget.userAmount!.toInt().toString(),
                                              maxLines: 1,
                                              minFontSize: 0.1,
                                              stepGranularity: 0.1,
                                              textAlign: TextAlign.start,
                                              style: Theme.of(context).textTheme.displayLarge!.copyWith(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            )
                                          ])
                                        : Container(),
                                  ),
                                ),
                              ),
                              if (widget.userAmount != null && widget.userAmount! > 0.0 && ((width * widget.percentage) * widget.userPercentage!) <= width * 0.1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: AutoSizeText(
                                      widget.userAmount!.toInt().toString(),
                                      maxLines: 1,
                                      minFontSize: 0.1,
                                      stepGranularity: 0.1,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (widget.goal > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.funding_target,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(
                                width: 25,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 0.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatNumber(widget.goal),
                                      style: Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white70),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
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
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
       if (widget.amount >= widget.goal)
       Container(
              width: MediaQuery.of(context).size.width,
              height: 110,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8C826),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 1), // changes position of shadow
                  ),
                ],
              ),
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.title, textAlign:TextAlign.center, style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.black87, fontSize: 16.0, fontWeight: FontWeight.w800),),
                  const SizedBox(height: 5,),
                  Text("${formatNumber(widget.goal)} 2XDN", textAlign:TextAlign.center, style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.black87, fontSize: 14.0, fontWeight: FontWeight.w800),),
                  const SizedBox(height: 5,),
                  Text(AppLocalizations.of(context)!.fully_funded, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w200, color: Colors.black87),),
                ],
              )),
            ),

      ],
    );
  }

  List<BoxShadow>? _getShadow(double userSize) {
    if (userSize != 0.0) {
      return const [
        BoxShadow(
          color: Color(0xFF298C2D),
          blurRadius: 0.1,
          spreadRadius: 0.1,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0xFF5FC562),
          blurRadius: 0.2,
          spreadRadius: 0.2,
          offset: Offset(1, 0),
        ),
      ];
    } else {
      return null;
    }
  }

  String formatNumber(int number) {
    NumberFormat nf = NumberFormat("##.###");
    if (number < 1000) {
      return number.toString();
    } else if ((number / 1000) > 1 && (number / 1000) < 1000) {
      return '${nf.format(number / 1000)}k';
    } else if ((number / 1000000) > 1 && (number / 1000000) < 1000) {
      return '${nf.format(number / 1000000)}m';
    } else {
      return number.toString();
    }
  }
}
