import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class DataBar extends StatefulWidget {
  final String title;
  final double percentage;
  final double amount;
  final double? userPercentage;
  final double? userAmount;
  final int index;

  const DataBar({Key? key, required this.title, required this.percentage, this.userPercentage, required this.amount, this.userAmount, required this.index}) : super(key: key);

  @override
  State<DataBar> createState() => _DataBarState();
}

class _DataBarState extends State<DataBar> with TickerProviderStateMixin {
  double size = 0.0;
  double? userSize;

  @override
  void initState() {
    super.initState();
    if (widget.userPercentage != null) {
      userSize = 0.0;
    }
    Future.delayed(Duration(milliseconds: (250 * widget.index)), () {
      setState(() {
        size = widget.percentage;
      });
    });
    Future.delayed(Duration(milliseconds: (250 * widget.index + 100)), () {
      setState(() {
        userSize = widget.userPercentage;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: LayoutBuilder(builder: (context, constrains) {
        var width = constrains.maxWidth;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              child: Container(
                height: 25,
                width: width * size,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                ),
                child: Row(children: [
                  const Expanded(child: SizedBox()),
                  if (width * widget.percentage > width * 0.05)
                    AutoSizeText(
                      widget.amount.toInt().toString(),
                      maxLines: 1,
                      minFontSize: 0.1,
                      stepGranularity: 0.1,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  SizedBox(width: 5,)
                ]),
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            if (userSize != null)
            AnimatedSize(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              child: Container(
                height: 15,
                width: (width * widget.percentage) * userSize!,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                ),
                child: Row(children: [
                  const Expanded(child: SizedBox()),
                  if (widget.userAmount != null && ((width * widget.percentage) * widget.userPercentage!) > width * 0.05)
                  AutoSizeText(
                    widget.userAmount!.toInt().toString(),
                    maxLines: 1,
                    minFontSize: 0.1,
                    stepGranularity: 0.1,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 5,)
                ]),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        );
      }),
    );
  }
}
