import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:konjungate/support/Message.dart';

import '../globals.dart' as globals;
import '../support/AppDatabase.dart';
import '../support/CardHeader.dart';
import '../support/ColorScheme.dart';
import '../support/DateSeparator.dart';
import '../support/Dialogs.dart';
import '../support/LifecycleWatcherState.dart';
import '../support/MessageBubble.dart';
import '../support/MessageGroup.dart';
import '../support/NetInterface.dart';
import '../widgets/AvatarPicker.dart';
import '../widgets/backgroundWidget.dart';

class MessageDetailScreen extends StatefulWidget {
  final MessageGroup mgroup;
  final Function(String addr)? func;

  const MessageDetailScreen({Key? key, required this.mgroup, this.func}) : super(key: key);

  @override
  MessageDetailScreenState createState() => MessageDetailScreenState();
}

class MessageDetailScreenState extends LifecycleWatcherState<MessageDetailScreen> {
  Future<List<dynamic>>? _messages;
  final _storage = const FlutterSecureStorage();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _addr;
  String? _lastDate;
  var _running = true;
  var _busy = false;
  var _circleVisible = false;
  final _tip = true;
  Widget? _switchWidget;
  bool _withoutNot = false;
  String? _replyMessage;
  int _replyid = 0;
  double _replyHeight = 0.0;
  Timer? timer;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _messages = _getMessages();
    _checkForMessages();
    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
      if(_running == true)  {
        _checkForMessages();
      }
    });
    _switchWidget = _tipIcon();
    _textController.addListener(() {
      if (_textController.text.isEmpty) {
        setState(() {
          if (!_circleVisible) _switchWidget = _tipIcon();
        });
      } else {
        setState(() {
          if (!_circleVisible) _switchWidget = _sendIcon();
        });
      }
    });
  }

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<List<dynamic>> _getMessages() async {
    String? ss = await NetInterface.getBalance(details: true);
    var sjson = json.decode(ss!);
    _balance = (double.parse(sjson["balance"]));
    _addr = await _storage.read(key: globals.ADR);
    var s = await AppDatabase().getMessages(_addr!, widget.mgroup.sentAddressOrignal!);

    return s!;
  }

  void notReceived() {
    _withoutNot = false;
    if (_running) {

      Future.delayed(const Duration(milliseconds: 10), () {
        _checkForMessages();
      });
    }
  }

  void _iconReset() {
    setState(() {
      if (_textController.text.isEmpty) {
        setState(() {
          if (!_circleVisible) _switchWidget = _tipIcon();
        });
      } else {
        setState(() {
          if (!_circleVisible) _switchWidget = _sendIcon();
        });
      }
    });
  }

  void _checkForMessages() async {
    _addr = await _storage.read(key: globals.ADR);
    if (_busy) return;
    setState(() {
      _busy = true;
      _messages = null;
    });
    try {
      int idMax = await AppDatabase().getMessageGroupMaxID(_addr, widget.mgroup.sentAddressOrignal);
      await NetInterface.saveMessages(widget.mgroup.sentAddressOrignal!, idMax);
      setState(() {
        _messages = AppDatabase().getMessages(_addr!, widget.mgroup.sentAddressOrignal!);
        _circleVisible = false;
        _iconReset();
        _busy = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) {
      Dialogs.openMessageTipBox(context, widget.mgroup.sentAddr!, widget.mgroup.sentAddressOrignal!, _sendBoxCallback);
    } else {
      setState(() {
        _switchWidget = _sendWait();
        _circleVisible = true;
      });

      await NetInterface.sendMessage(widget.mgroup.sentAddressOrignal!, _textController.text.trimRight(), _replyid);
      _textController.text = '';
      _withoutNot = true;
      setState(() {
        _replyid = 0;
        _replyMessage = null;
        _replyHeight = 0.0;
      });
      Future.delayed(const Duration(milliseconds: 7000), () {
        if (_withoutNot) {
          setState(() {
            _withoutNot = false;
            _checkForMessages();
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.message_not_warning),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.fixed,
            elevation: 5.0,
          ));
        }
      });
    }
  }

  void _sendBoxCallback(String amount, String name, String addr) async {
    Navigator.of(context).pop();
    // Dialogs.openWaitBox(context);

    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.amount_empty),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        elevation: 5.0,
      ));
      return;
    } else if(double.parse(amount) > _balance) {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.st_insufficient + "!");
      return;

    } else if (addr.length != 34 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(addr) || addr[0] != 'K') {
      Dialogs.displayDialog(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.konj_addr_invalid);
      return;
    } else {
      setState(() {
        _switchWidget = _sendWait();
        _circleVisible = true;
      });
      int _i = await NetInterface.sendContactCoins(amount, name, addr);
      var _nick = await _storage.read(key: globals.NICKNAME);
      if (_i == 1) {
        var _text = _nick! + " " + AppLocalizations.of(context)!.message_tipped +" " + widget.mgroup.sentAddr! + " " + amount.toString() + " KONJ!";
        await NetInterface.sendMessage(widget.mgroup.sentAddressOrignal!, _text, _replyid);
        setState(() {
          _switchWidget = _sendWait();
          _circleVisible = true;
          _withoutNot = true;
        });

        Future.delayed(const Duration(milliseconds: 7000), () {
          if (_withoutNot) {
            setState(() {
              _withoutNot = false;
              _checkForMessages();
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.message_not_warning),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.fixed,
              elevation: 5.0,
            ));
          }
        });
      } else if (_i == 2) {
        Navigator.of(context).pop();
        Dialogs.openInsufficientBox(context);
      }
    }
  }

  void _reply(String s, int id) {
    setState(() {
      _replyid = id;
      _replyMessage = s;
      _replyHeight = 45.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        image: "messageicon.png",
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 65.0, bottom: 0.0, left: 5.0, right: 5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FutureBuilder(
                            future: _messages,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                var _data = snapshot.data as List<dynamic>?;
                                return Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                                      child: ListView.builder(
                                          reverse: true,
                                          controller: _scrollController,
                                          shrinkWrap: true,
                                          itemCount: _data!.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            dynamic _node = _data[index];
                                            if (_node is DateSeparator) {
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 30.0, bottom: 10.0),
                                                    decoration: const BoxDecoration(color: Color.fromRGBO(44, 44, 53, 1.0), borderRadius: BorderRadius.all(Radius.circular(32.0))),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(15.0),
                                                      child: Text(
                                                        _node.lastMessage!,
                                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white70, fontSize: 14.0),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return MessageBubble(
                                                key: Key((_node as Message).id.toString()),
                                                messages: _data[index],
                                                userMessage: _data[index].sentAddr == _addr ? true : false,
                                                replyCallback: _reply,
                                                // func3: _refreshUsers,
                                              );
                                            }
                                          }),
                                    ),
                                  ),
                                );
                              } else {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 200.0),
                                  child: SizedBox(child: CircularProgressIndicator( color: Colors.white, strokeWidth: 2.0,), height: 50.0, width: 50.0),
                                );
                              }
                            }),
                        const SizedBox(
                          height: 30.0,
                        ),
                        const SizedBox(height: 10.0),
                        Wrap(children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).konjHeaderColor,
                              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                            ),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.decelerate,
                                  width: MediaQuery.of(context).size.width,
                                  height: _replyHeight,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).konjTextFieldHeaderColor,
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0)),
                                  ),
                                  child: Center(
                                    child: SingleChildScrollView(
                                      child: SizedBox(
                                        height: _replyHeight,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 15.0,
                                            ),
                                            Text(
                                              AppLocalizations.of(context)!.message_reply_to +': ',
                                              style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14.0),
                                            ),
                                            const SizedBox(
                                              width: 5.0,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.6,
                                              child: AutoSizeText(
                                                _replyMessage == null ? '' : _replyMessage!,
                                                style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0),
                                                maxLines: 1,
                                                minFontSize: 12.0,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5.0,
                                            ),
                                            Expanded(
                                                child: Material(
                                              color: const Color(0xFFc74d4d),
                                              borderRadius: const BorderRadius.only(topRight: Radius.circular(15.0)),
                                              child: InkWell(
                                                borderRadius: const BorderRadius.only(topRight: Radius.circular(15.0)),
                                                splashColor: const Color(0xFFc74d4d).withOpacity(0.5), // splash color
                                                onTap: () {
                                                  setState(() {
                                                    _replyid = 0;
                                                    _replyMessage = null;
                                                    _replyHeight = 0;
                                                  });
                                                }, // button pressed
                                                child: SizedBox(
                                                  height: _replyHeight,
                                                  child: Center(
                                                    child: Text('x', style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 20.0)),
                                                  ),
                                                ),
                                              ),
                                            ))
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 15.0, right: 5.0, bottom: 5.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextField(
                                          autofocus: false,
                                          textCapitalization: TextCapitalization.sentences,
                                          controller: _textController,
                                          keyboardType: TextInputType.multiline,
                                          inputFormatters: <TextInputFormatter>[
                                            LengthLimitingTextInputFormatter(720),
                                          ],
                                          textAlign: TextAlign.left,
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.white),
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.all(15.0),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white30),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white),
                                            ),
                                          ),
                                          maxLines: null,
                                        ),
                                        // child: RoundedContainer(controller: _textController,),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 5.0, top: 5.0),
                                          child: SizedBox(
                                            width: 55,
                                            height: 55,
                                            child: GestureDetector(
                                              onTap: () {
                                                if (!_circleVisible) {
                                                  _sendMessage();
                                                }
                                              },
                                              child: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 200),
                                                transitionBuilder: (Widget child, Animation<double> animation) {
                                                  return ScaleTransition(child: child, scale: animation);
                                                },
                                                child: _switchWidget,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(children: [
                Container(
                  margin: const EdgeInsets.only(top: 8.0, left: 75),
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          AvatarPicker(
                            userID: widget.mgroup.sentAddressOrignal,
                            size: 60.0,
                            color: Colors.white,
                            padding: 2.0,
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          SizedBox(
                            width: 200,
                            height: 20,
                            child: AutoSizeText(widget.mgroup.sentAddr!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 14.0,
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.bodyText2!.copyWith(
                                      fontSize: 20.0,
                                    )),
                          ),
                        ],
                      ),
                      const Visibility(
                        visible: false,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 0.0, right: 30),
                            child: SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      CardHeader(
        title: '',
        backArrow: true,
      ),
    ]);
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
    _checkForMessages();
    Future.delayed(const Duration(milliseconds: 500), () {
      _running = true;
    });
  }

  Widget _sendIcon() {
    return const Icon(
      Icons.expand_less,
      size: 45,
      color: Colors.white,
      key: ValueKey<int>(0),
    );
  }

  Widget _tipIcon() {
    return SizedBox(
      width: 40,
      child: Image.asset(
        "images/konjicon.png",
        key: const ValueKey<int>(1),
      ),
    );
  }

  Widget _sendWait() {
    return const SizedBox(
      width: 25,
      height: 25,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        key: ValueKey<int>(2),
        color: Colors.white,
      ),
    );
  }
}
