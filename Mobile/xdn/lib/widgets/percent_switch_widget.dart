import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class PercentSwitchWidget extends StatefulWidget {
  final Function(double percent) changePercent;
  const PercentSwitchWidget({Key? key, required this.changePercent}) : super(key: key);

  @override
  PercentSwitchWidgetState createState() => PercentSwitchWidgetState();
}

class PercentSwitchWidgetState extends State<PercentSwitchWidget> {
  var _active = 5;
  final _duration = const Duration(milliseconds: 300);

  void deActivate() {
    setState(() {
      _active = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width * 0.23;
    return SizedBox(
        width: width * 4,
        child: Row(
            children: [
              SizedBox(
                width: width,
                child: AnimatedOpacity(
                  opacity: _active == 4 ? 1.0 : 0.4,
                  duration: _duration,
                  child: TextButton(
                      onPressed: () async {
                        widget.changePercent(0.25);
                        await Future.delayed(const Duration(milliseconds: 300), () {
                          setState(() {
                            _active = 4;
                          });
                        });

                      },
                      child: AutoSizeText("25 %",
                          minFontSize: 12,
                          maxLines: 1,
                          style:  Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0, fontWeight: FontWeight.bold)
                      )),),
              ),
              SizedBox(
                width: width,
                child: AnimatedOpacity(
                  opacity: _active == 3 ? 1.0 : 0.4,
                  duration: _duration,
                  child: TextButton(
                      onPressed: () async {
                        widget.changePercent(0.5);
                        await Future.delayed(const Duration(milliseconds: 300), () {
                          setState(() {
                            _active = 3;
                          });
                        });
                      },
                      child: AutoSizeText(
                          "50 %",
                          minFontSize: 6,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0, fontWeight: FontWeight.bold)
                      )),),
              ),
              SizedBox(
                width: width,
                child: AnimatedOpacity(
                  opacity: _active == 2 ? 1.0 : 0.4,
                  duration: _duration,
                  child: TextButton(
                      onPressed: () async {
                        widget.changePercent(0.75);
                          await Future.delayed(const Duration(milliseconds: 300), () {
                            setState(() {
                              _active = 2;
                            });
                          });
                      },
                      child: AutoSizeText("75 %",
                          minFontSize: 6,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0, fontWeight: FontWeight.bold))),
                ),
              ),
              SizedBox(
                width: width,
                child: AnimatedOpacity(
                  opacity: _active == 1 ? 1.0 : 0.4,
                  duration: _duration,
                  child: TextButton(
                      onPressed: () async {
                        widget.changePercent(1.0);
                        await Future.delayed(const Duration(milliseconds: 300), () {
                          setState(() {
                            _active = 1;
                          });
                        });
                      },
                      child: AutoSizeText(
                        "MAX",
                        minFontSize: 6,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0, fontWeight: FontWeight.bold),
                      )),
                ),
              )
            ]));
  }
}