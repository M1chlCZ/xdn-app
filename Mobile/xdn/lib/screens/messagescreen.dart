import 'dart:async';

import 'package:digitalnote/support/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/messageComposeScreen.dart';
import '../support/AppDatabase.dart';
import '../support/CardHeader.dart';
import '../support/ColorScheme.dart';
import '../support/LifecycleWatcherState.dart';
import '../support/MessageGroup.dart';
import '../support/MessageGroupTile.dart';
import '../support/NetInterface.dart';
import '../support/RoundButton.dart';
import '../widgets/backgroundWidget.dart';
import 'messageDetailScreen.dart';

class MessageScreen extends StatefulWidget {
  static const String route = "/menu/messages";
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
    // fmc.bodyCtlr.stream.listen((event) {print(event + " Messages");});  //TODO Notifications stream
    // AppDatabase().deleteTableAddr();
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
        }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        }))
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
                CardHeader(
                  title: AppLocalizations.of(context)!.messages,
                  backArrow: true,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 0.0, right: 0.0),
                  padding: const EdgeInsets.only(top: 15.0, left: 5.0, bottom: 10.0),
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
                                fillColor: Theme.of(context).konjHeaderColor,
                                hintStyle: GoogleFonts.montserrat(fontStyle: FontStyle.normal, color: Colors.white70),
                                labelText: AppLocalizations.of(context)!.message_search,
                                labelStyle: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).konjHeaderColor, width: 2.0), borderRadius: const BorderRadius.all(Radius.circular(10.0)))),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 5.0, top: 0.0),
                      child: RoundButton(
                          height: 45,
                          width: 80,
                          radius: 10.0,
                          color: Theme.of(context).konjHeaderColor,
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
                Expanded(
                  child: FutureBuilder(
                      future: _messageGroup,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var _data = snapshot.data as List<MessageGroup>;
                          var _length = _data.length;
                          return Padding(
                            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _length,
                                itemBuilder: (BuildContext context, int index) {
                                  return MessageGroupTile(
                                    key: Key(_data[index].lastReceivedMessage!),
                                    mgroup: _data[index],
                                    callbackMgroup: _callbackMgroup,
                                    func3: _getMessages,
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
                            child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: const <Widget>[
                              SizedBox(child: CircularProgressIndicator(color: Colors.white,strokeWidth: 2.0), height: 50.0, width: 50.0),
                            ]),
                          );
                        }
                      }),
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
