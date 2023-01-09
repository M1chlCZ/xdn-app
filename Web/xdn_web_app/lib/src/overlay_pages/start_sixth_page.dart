import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xdn_web_app/src/models/TXInfo.dart';
import 'package:xdn_web_app/src/provider/mn_provider.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/extensions.dart';
import 'package:xdn_web_app/src/support/s_p.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';
import 'package:http/http.dart' as http;

class SixthOvrPage extends ConsumerStatefulWidget {
  const SixthOvrPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SixthOvrPage> createState() => _SixthOvrPageState();
}

class _SixthOvrPageState extends ConsumerState<SixthOvrPage> {
  int confirmations = 5;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rrr = ref.watch(mnProvider.notifier);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        gapH20,
        const Text(
          'Step 5',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 24.0),
        ),
        if (confirmations > 14)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            gapH32,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Go to your QT wallet to Masternode section and then click on ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
                Text(
                  '${rrr.getMNConf}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.0),
                ),
                const Text(
                  ' and then press start',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
              ],
            ),
            gapH12,
            SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Image.asset("assets/images/tut_start.png")),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: FlatCustomButton(
                height: 50,
                width: MediaQuery.of(context).size.width * 0.3,
                radius: 8,
                splashColor: Colors.amber,
                color: Colors.green,
                onTap: () {
                 context.pop();
                },
                child: Text(
                  "I started ${rrr.getMNConf} in my QT wallet".hardcoded,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        if (confirmations < 15)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Please wait until tx will have 15 confirmations, this screen will automatically refresh, don't close the window",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14.0),
                  ),
                ],
              ),
              gapH32,
              StreamBuilder<int>(
                stream: checkConfirmations(),
                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                  if (snapshot.hasData) {
                    Future.delayed(Duration.zero, () {
                      if (mounted) {
                        setState(() {
                          confirmations = snapshot.data!;
                        });
                      }
                    });
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Confirmations: ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 18.0),
                      ),
                      gapW8,
                      Text(
                        '${snapshot.data ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18.0),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  Stream<int> checkConfirmations() async* {
    yield* Stream.periodic(const Duration(seconds: 5), (_) async {
      debugPrint('checkConfirmations');
      final rrr = ref.watch(mnProvider.notifier);
      var res = await http.get(Uri.parse("https://xdn-explorer.com/ext/gettx/${rrr.getTx}"));
      if (res.statusCode == 200) {
        var r = json.decode(res.body);
        var txinfo = TXInfo.fromJson(r);
        return txinfo.confirmations ?? 0;
      }else{
        return 0;
      }
    }).asyncMap((event) async => await event);
  }
}