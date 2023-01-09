import 'package:flutter/material.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';

class StartOvrPage extends StatelessWidget {
  const StartOvrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        gapH20,
        const Text(
          'Prerequisites',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 24.0),
        ),
        gapH16,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              '1) Add ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14.0),
            ),
            SelectableText(
              'mnconflock=1',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
            ),
            Text(
              'in your DigitalNote.conf file as shown on pictures below',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14.0),
            ),
          ],
        ),
        gapH24,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              '2) Restart your QT wallet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14.0),
            ),
          ],
        ),
        gapH24,
        SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Image.asset("assets/images/start_mn4.png")),
        gapH12,
        const Text(
          "This will ensure that you don't accidentally send out MN collateral from your existing nodes while building new MN",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14.0),
        ),
      ],
    );
  }
}
