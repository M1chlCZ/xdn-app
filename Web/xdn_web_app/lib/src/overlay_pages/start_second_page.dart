import 'package:flutter/material.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';

class SecondOvrPage extends StatelessWidget {
  const SecondOvrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        gapH20,
        const Text(
          'Step 1',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 24.0),
        ),
        gapH16,
         Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Open debug console in your QT wallet ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14.0),
            ),
          ],
        ),
        gapH24,
        SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Image.asset("assets/images/start_mn2.png")),
      ],
    );
  }
}
