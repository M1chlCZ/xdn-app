import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/notification_helper.dart';
import 'package:digitalnote/widgets/MessageGroupTile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/messageComposeScreen.dart';
import '../support/AppDatabase.dart';
import '../support/CardHeader.dart';
import '../support/LifecycleWatcherState.dart';
import '../models/MessageGroup.dart';
import '../support/NetInterface.dart';
import '../support/RoundButton.dart';
import '../widgets/backgroundWidget.dart';
import 'message_detail_screen.dart';

class MessageScreen extends StatefulWidget {
  static const String route = "menu/messages";

  const MessageScreen({
    Key? key,
  }) : super(key: key);

  @override
  MessageScreenState createState() => MessageScreenState();
}

class MessageScreenState extends LifecycleWatcherState<MessageScreen> {
  final _childKey = GlobalKey<MessageDetailScreenState>();
  var _running = true;
  var _busy = false;
  FCM fmc = GetIt.I.get<FCM>();
  final TextEditingController _controller = TextEditingController();
  Future<List<MessageGroup>>? _messageGroup;

  void notReceived() {
    if (_childKey.currentWidget != null) {
      _childKey.currentState!.notReceived();
    } else {
      if (_running) {
        _getMessages();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _messageGroup = _getMessageGroups();
    _getMessages();
    _controller.addListener(() {
      setState(() {
        _messageGroup = AppDatabase().searchMessages(_controller.text);
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _getMessages();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<MessageGroup>> _getMessageGroups() async {
    return AppDatabase().getMessageGroup();
  }

  Future<void> _getMessages() async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      await NetInterface.saveMessageGroup().then((value) => _showMessages());
    } catch (e) {
      // print(e);
    }
  }

  void _showMessages() async {
    setState(() {
      _messageGroup = AppDatabase().getMessageGroup();
      _busy = false;
    });
  }

  Future<void> _updateRead(String addr) async {
    await NetInterface.updateRead(addr);
    await _getMessages();
  }

  void _callbackMgroup(MessageGroup mg) {
    Navigator.of(context)
        .push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
          return MessageDetailScreen(
            key: _childKey,
            mgroup: mg,
            func: _updateRead,
          );
        }, ))
        .then((value) => _updateRead(mg.sentAddressOrignal!));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(
          image: "messageicon.png",
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8.0, left: 5.0),
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 15.0),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          color: Colors.transparent,
                          child: const CardHeader(
                            title: '',
                            backArrow: true,
                            noPadding: true,
                          ),
                        ),
                        Expanded(
                          child: AutoSizeText(AppLocalizations.of(context)!.messages,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 16.0,
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                                fontSize: 24.0,
                                color: Colors.white.withOpacity(0.85),
                              )),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                  padding: const EdgeInsets.only(top: 5.0, left: 5.0, bottom: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  ),
                  child: Center(
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Flexible(
                        child: FractionallySizedBox(
                          widthFactor: 0.95,
                          child: SizedBox(
                            height: 45,
                            child: TextField(
                              controller: _controller,
                              style: GoogleFonts.montserrat(fontStyle: FontStyle.normal, color: Colors.white),
                              decoration: InputDecoration(
                                  filled: true,
                                  hoverColor: Theme.of(context).cardColor,
                                  focusColor: Theme.of(context).cardColor,
                                  fillColor: const Color(0xFF22283A).withOpacity(0.5),
                                  hintStyle: GoogleFonts.montserrat(fontStyle: FontStyle.normal, color: Colors.white70),
                                  labelText: AppLocalizations.of(context)!.message_search,
                                  labelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: const Color(0xFF22283A).withOpacity(0.1), width: 2.0),
                                      borderRadius: const BorderRadius.all(Radius.circular(10.0))),
                                  enabledBorder:  OutlineInputBorder(
                                      borderSide: BorderSide(color: const Color(0xFF22263A).withOpacity(0.1), width: 2.0),
                                      borderRadius: const BorderRadius.all(Radius.circular(10.0)))),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0, top: 0.0),
                        child: RoundButton(
                            height: 43,
                            width: 65,
                            radius: 12.0,
                            color: const Color(0xFF4B9B4C).withOpacity(0.8),
                            onTap: () {
                              Navigator.of(context)
                                  .push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
                                    return MessageComposeScreen(
                                      func: _updateRead,
                                    );
                                  }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  }))
                                  .then((value) => _getMessages());
                            },
                            splashColor: Colors.black45,
                            imageIcon: Image.asset(
                              "images/newmessage.png",
                              height: 30,
                              width: 30,
                              fit: BoxFit.fitHeight,
                              color: Colors.white70,
                            )),
                      ),
                    ]),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 5.0, right: 5.0, top: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                    ),
                    child: FutureBuilder(
                        future: _messageGroup,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            var data = snapshot.data as List<MessageGroup>;
                            var length = data.length;
                            return Padding(
                              padding: const EdgeInsets.only(left: 3.0, right: 3.0),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2.0),
                                      child: MessageGroupTile(
                                        key: Key(data[index].lastReceivedMessage!),
                                        mgroup: data[index],
                                        callbackMgroup: _callbackMgroup,
                                        func3: _getMessages,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              height: MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                              color: Colors.transparent,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const <Widget>[
                                    SizedBox(height: 50.0, width: 50.0, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)),
                                  ]),
                            );
                          }
                        }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {
    _running = false;
  }

  @override
  void onResumed() {
    _getMessages();
    Future.delayed(const Duration(milliseconds: 500), () {
      _running = true;
    });
  }
}
