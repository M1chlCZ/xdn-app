import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/LifecycleWatcherState.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/auto_size_text_field.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:digitalnote/widgets/social_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user.dart';
import '../widgets/button_flat.dart';

class SocialScreen extends StatefulWidget {
  static const String route = "menu/settings/socials";

  const SocialScreen({Key? key}) : super(key: key);

  @override
  SocialScreenState createState() => SocialScreenState();
}

class SocialScreenState extends LifecycleWatcherState<SocialScreen> {
  final ComInterface _interface = ComInterface();
  final TextEditingController _discordTextController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _paused = false;
  String? tokenLink;
  bool _linked = false;
  String? _name;
  User? _me;

  bool _discordDetails = false;

  @override
  void initState() {
    super.initState();
    getTokenLink();
  }

  getTokenLink() async {
    var token = await _interface.get("/user/bot", serverType: ComInterface.serverGoAPI, debug: true);
    if (token != null) {
      setState(() {
        tokenLink = token['token'];
        _linked = token['linked'];
        _name = token['user'];
      });
      _discordTextController.text = '/register $tokenLink';
    }
  }

  void unlinkToken() async {
    try {
      var token = await _interface.post("/user/bot/unlink", serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: true);
      if (token != null) {
        setState(() {
          _linked = false;
        });
      }
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

  void showInSnackBar(String value) {
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
              name: _name,
              cardActiveColor: const Color(0xFF1DA1F2),
              pictureName: 'images/socials_general.png',
              onTap: () async {
                setState(() {
                  if (_discordDetails) {
                    _discordDetails = false;
                  } else {
                    _discordDetails = true;
                  }
                });
                // if (!_socials.contains(3)) {
                //   // await _loadTwitterDirective();
                //   // _launchURL(_twitter!.data!.url!);
                // }
              },
              unlink: unlinkToken,
              socials: _linked,
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _discordDetails ? 1.0 : 0.0,
              child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    color: Color(0xFF7289DA),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              _launchURL('https://t.me/xdntip_bot');
                            },
                            child: Row(
                              children: [
                                Text(
                                  '- ${AppLocalizations.of(context)!.join_discord}',
                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0),
                                ),
                                const SizedBox(
                                  width: 5.0,
                                ),
                                const Icon(
                                  Icons.open_in_new,
                                  color: Colors.white,
                                  size: 14.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              Text(
                                '- ${AppLocalizations.of(context)!.send_discord}',
                                style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Container(
                          // margin: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                          width: double.infinity,
                          height: 30.0,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(4.0)),
                            color: Color(0xFF252525),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.82,
                                  child: AutoSizeTextField(
                                    maxLines: 1,
                                    minFontSize: 8.0,
                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white, fontSize: 14.0),
                                    autocorrect: false,
                                    readOnly: true,
                                    controller: _discordTextController,
                                    textAlign: TextAlign.left,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.only(left: 4.0, right: 4.0),
                                      isDense: true,
                                      hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(color: Colors.white54, fontSize: 14.0),
                                      hintText: '',
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.transparent),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.transparent),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 0.0, right: 3.0),
                                  child: SizedBox(
                                    width: 30.0,
                                    height: 25.0,
                                    child: FlatCustomButton(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: '/register $tokenLink'));
                                          showInSnackBar(AppLocalizations.of(context)!.dl_priv_copy);
                                        },
                                        color: const Color(0xFF7289DA),
                                        splashColor: Colors.black38,
                                        child: const Icon(
                                          Icons.content_copy,
                                          size: 18.0,
                                          color: Colors.white,
                                        )),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            )
          ]),
        )
      ]),
    );
  }

  void _launchURL(String url) async {
    var kUrl = url.replaceAll(" ", "+");
    Utils.openLink(kUrl);
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
