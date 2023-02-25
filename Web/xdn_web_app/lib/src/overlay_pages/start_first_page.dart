import 'package:flutter/material.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/utils.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';

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
        const Text(
          '1) You have to have at least 2 000 000 XDN.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14.0),
        ),
        gapH16,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '2) Download the latest wallet, from ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14.0),
            ),
            GestureDetector(
              onTap: () {

              },
              child: FlatCustomButton(
                radius: 8,
                color: Colors.black12,
                onTap: () {
                  Utils.openLink('https://digitalnote.org/#wallets');
                },
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Row(
                    children: const [

                      Text('link', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),),
                    gapW4,
                      Icon(Icons.open_in_new, color: Colors.white, size: 12,)

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        gapH8,
        const Text(
          "It's important to do so, otherwise you won't be able to start the masternode" ,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontSize: 10.0),
        ),
        gapH16,
         Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              '3) Add ',
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
              '4) Restart your QT wallet',
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
