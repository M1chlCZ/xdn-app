import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:flutter/material.dart';

class BugSwitcher extends StatefulWidget {
  final Function(int page)? switchPage;

  const BugSwitcher({Key? key, this.switchPage}) : super(key: key);

  @override
  BugSwitcherState createState() => BugSwitcherState();
}

class BugSwitcherState extends State<BugSwitcher> {
  var _active = 0;
  final _duration = const Duration(milliseconds: 300);

  currentPage(int p) {
    setState(() {
      _active = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 45,
      child: Container(
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10.0)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Expanded(
              child: AnimatedContainer(
                decoration: BoxDecoration(color: _active == 0 ? Colors.lightGreen : Colors.transparent, borderRadius: BorderRadius.circular(5.0)),
                duration: _duration,
                child: FlatCustomButton(
                    color: Colors.transparent,
                    radius: 5.0,
                    onTap: () {
                      setState(() {
                        _active = 0;
                      });
                      widget.switchPage!(0);
                    },
                    child: SizedBox(
                      width: 120,
                      height: 35,
                      child: Center(
                          child: AutoSizeText("Report bug",
                              maxLines: 1,
                              minFontSize: 8.0,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold, color: _active == 0 ? Colors.black87 : Colors.white38))),
                    )),
              ),
            ),
            const SizedBox(
              width: 5.0,
            ),
            Container(
              height: 40,
              width: 1.0,
              color: Colors.white12,
            ),
            const SizedBox(
              width: 5.0,
            ),
            Expanded(
              child: AnimatedContainer(
                decoration: BoxDecoration(color: _active == 1 ? Colors.lightGreen : Colors.transparent, borderRadius: BorderRadius.circular(5.0)),
                duration: _duration,
                child: FlatCustomButton(
                    color: Colors.transparent,
                    radius: 5.0,
                    onTap: () {
                      setState(() {
                        _active = 1;
                      });
                      widget.switchPage!(1);
                    },
                    child: SizedBox(
                      width: 120,
                      height: 35,
                      child: Center(
                        child: AutoSizeText("Your reports",
                            maxLines: 1,
                            minFontSize: 12.0,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold, color: _active == 1 ? Colors.black87 : Colors.white38)),
                      ),
                    )),
              ),
            ),
          ])),
    );
  }
}
