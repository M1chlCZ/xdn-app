import 'package:flutter/material.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';

class ThirdOvrPage extends StatelessWidget {
  const ThirdOvrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        gapH20,
        const Text(
          'Step 2',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 24.0),
        ),
        gapH16,
         Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  '1) In console write ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
                SelectableText(
                  'getnewaddress ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14.0,fontWeight: FontWeight.bold),
                ),
                Text(
                  'hit enter, copy address to clipboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
              ],
            ),
            gapH16,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  '2) Type in console ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
                SelectableText(
                  'sendtoaddress <generated address> 2000000',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14.0,fontWeight: FontWeight.bold),
                ),
                Text(
                  ' and hit enter',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
              ],
            ),
            gapH16,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  '3) If there is no error go to next step ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
              ],
            ),
          ],
        ),
        gapH16,
        SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Image.asset("assets/images/start_mn3.png")),
      ],
    );
  }
}
