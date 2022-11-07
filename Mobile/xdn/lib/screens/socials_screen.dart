import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/LifecycleWatcherState.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/social_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SocialScreen extends StatefulWidget {
  static const String route = "menu/settings/socials";

  const SocialScreen({Key? key}) : super(key: key);

  @override
  SocialScreenState createState() => SocialScreenState();
}

class SocialScreenState extends LifecycleWatcherState<SocialScreen> {
  final ComInterface _interface = ComInterface();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _paused = false;
  String? _tokenLink;

  bool _telegramDetails = false;

  String? _telegram;
  String? _discord;

  @override
  void initState() {
    super.initState();
    getTokenLink();
  }

  getTokenLink() async {
    var token = await _interface.get("/user/bot/connect", serverType: ComInterface.serverGoAPI, debug: false);
    if (token != null) {
      setState(() {
        _tokenLink = token['token'];
        _telegram = token['telegram'];
        _discord = token['discord'];
      });
    }

  }

  void unlinkBot(int typeBot) async {
    try {
      await _interface.post("/user/bot/unlink", serverType: ComInterface.serverGoAPI, body:{"typeBot" : typeBot}, type: ComInterface.typeJson, debug: true);
      getTokenLink();
    } catch (e) {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, e.toString());
    }
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value, textAlign: TextAlign.center,), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(children: [
        const BackgroundWidget(
          arc: false,
          mainMenu: false,
        ),
        SafeArea(
          child: Column(children: [
            Header(header: AppLocalizations.of(context)!.socials_popup.toLowerCase().capitalize()),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    AppLocalizations.of(context)!.social_accounts,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(fontSize: 14.0, color: Colors.white24),
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Container(
                    height: 0.5,
                    color: Colors.white12,
                  )
                ])),
            const SizedBox(
              height: 20.0,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(AppLocalizations.of(context)!.socials_info, style: const TextStyle(color: Colors.white70)),
            ),
            const SizedBox(
              height: 30.0,
            ),
            SocialMediaCard(
              name: _telegram ?? "XDN TIP Telegram Bot",
              cardActiveColor: const Color(0xFF229ED9),
              pictureName: 'images/telegram.png',
              onTap: () async {
                setState(() {
                  if (_telegramDetails) {
                    _telegramDetails = false;
                  } else {
                    _telegramDetails = true;
                  }
                });
                // if (!_socials.contains(3)) {
                //   // await _loadTwitterDirective();
                //   // _launchURL(_twitter!.data!.url!);
                // }
              },
              linkSocials: 'https://t.me/xdntip_bot',
              tokenCommand: "/register ${_tokenLink ?? ""}",
              showSnackBar: () {showInSnackBar(AppLocalizations.of(context)!.dl_priv_copy);},
              unlink: unlinkBot,
              socials: linkedCheck(_telegram), typeBot: 1,
            ),
            const SizedBox(
              height: 30.0,
            ),
            SocialMediaCard(
              name: _discord ?? "XDN TIP Discord Bot",
              cardActiveColor: const Color(0xFF7289DA),
              pictureName: 'images/discord.png',
              onTap: () {
              },
              linkSocials: 'https://discord.gg/S9bZmTTG4a',
              tokenCommand: "\$connect ${_tokenLink ?? ""}",
              showSnackBar: () {showInSnackBar(AppLocalizations.of(context)!.dl_priv_copy);},
              unlink: unlinkBot,
              socials: linkedCheck(_discord), typeBot: 2,
            ),
          ]),
        )
      ]),
    );
  }

  bool linkedCheck(String? social) {
    if (social == null) {
      return false;
    } else {
      return true;
    }
  }


  @override
  void onDetached() {
    _paused = true;
  }

  @override
  void onInactive() {
    _paused = true;
  }

  @override
  void onPaused() {
    _paused = true;
  }

  @override
  void onResumed() async {
    if (_paused) {
      getTokenLink();
      _paused = false;
    }
  }
}
