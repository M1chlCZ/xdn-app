import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/bloc/messages_bloc.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/support/notification_helper.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:digitalnote/models/Message.dart';
import 'package:get_it/get_it.dart';

import '../globals.dart' as globals;
import '../support/AppDatabase.dart';
import '../support/CardHeader.dart';
import '../models/DateSeparator.dart';
import '../support/Dialogs.dart';
import '../support/LifecycleWatcherState.dart';
import '../widgets/MessageBubble.dart';
import '../models/MessageGroup.dart';
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
  FCM fmc = GetIt.I.get<FCM>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final MessagesBloc mBlock = MessagesBloc();
  String? _addr;
  var _running = true;
  var _circleVisible = false;
  Widget? _switchWidget;
  String? _replyMessage;
  int _replyid = 0;
  double _replyHeight = 0.0;
  Timer? timer;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    // _messages = _getMessages();
    _getMessages();
    _getBalance();
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

    fmc.setNotifications();
    fmc.bodyCtlr.stream.listen((event) {
      notReceived(ev: event);
    });
  }

  void _getNewMessages() async {
    // var addr = await SecureStorage.read(key: globals.ADR);
    // int idMax = await AppDatabase().getMessageGroupMaxID(addr, widget.mgroup.sentAddressOrignal);
    // await NetInterface.saveMessages(widget.mgroup.sentAddressOrignal!, idMax);
    // mBlock.fetchMessages(widget.mgroup.sentAddressOrignal!);
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    mBlock.dispose();
    timer?.cancel();
    super.dispose();
  }

  _getMessages() async {
    _addr = await SecureStorage.read(key: globals.ADR);
    mBlock.fetchMessages(widget.mgroup.sentAddressOrignal!);
    // _getNewMessages();

    timer ??= Timer.periodic(const Duration(seconds: 5), (Timer t) {
      if (_running == true) {
        _getNewMessages();
        mBlock.refreshMessages(widget.mgroup.sentAddressOrignal!);
      }
    });
  }

  _getBalance() async {
    Map<String, dynamic>? ss = await NetInterface.getBalance(details: true);
    _balance = (double.parse(ss?["balance"]));
  }

  Future<void> notReceived({String? ev}) async {
    print("notReceived: $ev");
    // mBlock.refreshMessages(widget.mgroup.sentAddressOrignal!);
    if (_running) {
      Future.delayed(const Duration(milliseconds: 10), () {
        _getNewMessages();
        // mBlock.refreshMessages(widget.mgroup.sentAddressOrignal!);
        setState(() {
          _switchWidget = _tipIcon();
          _circleVisible = false;
        });
      });
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
      setState(() {
        _replyid = 0;
        _replyMessage = null;
        _replyHeight = 0.0;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _switchWidget = _tipIcon();
          _circleVisible = false;
          mBlock.refreshMessages(widget.mgroup.sentAddressOrignal!);
        });
        // _getNewMessages();
        // if (_withoutNot) {
        //   setState(() {
        //     _withoutNot = false;
        //     _switchWidget = _tipIcon();
        //     _circleVisible = false;
        //     mBlock.refreshMessages(widget.mgroup.sentAddressOrignal!);
        //   });
        // }
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
    } else if (double.parse(amount) > _balance) {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "${AppLocalizations.of(context)!.st_insufficient}!");
      return;
    } else if (addr.length != 34 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(addr) || addr[0] != 'd') {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.konj_addr_invalid);
      return;
    } else {
      setState(() {
        _switchWidget = _sendWait();
        _circleVisible = true;
      });
      int i = await NetInterface.sendContactCoins(amount, name, addr);
      if (i == 1) {
        var text = "&TIP# $amount XDN!";
        await NetInterface.sendMessage(widget.mgroup.sentAddressOrignal!, text, _replyid);
        setState(() {
          _switchWidget = _sendWait();
          _circleVisible = true;
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            _switchWidget = _tipIcon();
            _circleVisible = false;
            mBlock.refreshMessages(widget.mgroup.sentAddressOrignal!);
          });
        });
      } else if (i == 2) {
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
                padding: const EdgeInsets.only(top: 78.0, bottom: 0.0, left: 5.0, right: 5.0),
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
                        StreamBuilder<ApiResponse<List<dynamic>>>(
                            stream: mBlock.coinsListStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                switch (snapshot.data!.status) {
                                  case Status.completed:
                                    var mData = snapshot.data!.data as List<dynamic>;
                                    return Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                                          child: ListView.builder(
                                              reverse: true,
                                              controller: _scrollController,
                                              shrinkWrap: true,
                                              itemCount: mData.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                dynamic mNode = mData[index];
                                                if (mNode is DateSeparator) {
                                                  return Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets.only(top: 30.0, bottom: 10.0),
                                                        decoration: const BoxDecoration(
                                                            color: Color.fromRGBO(44, 44, 53, 1.0),
                                                            borderRadius: BorderRadius.all(Radius.circular(32.0))),
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(15.0),
                                                          child: Text(
                                                            mNode.lastMessage!,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodyText2!
                                                                .copyWith(color: Colors.white70, fontSize: 14.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  return MessageBubble(
                                                    key: Key((mNode as Message).id.toString()),
                                                    messages: mData[index],
                                                    userMessage: mData[index].sentAddr == _addr ? true : false,
                                                    replyCallback: _reply,
                                                    // func3: _refreshUsers,
                                                  );
                                                }
                                              }),
                                        ),
                                      ),
                                    );
                                  case Status.loading:
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 200.0),
                                      child: SizedBox(
                                          height: 50.0,
                                          width: 50.0,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0,
                                          )),
                                    );
                                  case Status.error:
                                    return Container();
                                }
                              } else {
                                return Container();
                              }
                            }),
                        const SizedBox(height: 10.0),
                        Wrap(children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF29303F),
                              borderRadius: BorderRadius.all(Radius.circular(15.0)),
                            ),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.decelerate,
                                  width: MediaQuery.of(context).size.width,
                                  height: _replyHeight,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1F222F),
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5.0), topRight: Radius.circular(5.0)),
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
                                            Expanded(
                                              child: AutoSizeText(
                                                '${AppLocalizations.of(context)!.message_reply_to}: ${_replyMessage == null ? '' : _replyMessage!}',
                                                style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0),
                                                maxLines: 1,
                                                minFontSize: 12.0,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5.0,
                                            ),
                                            // SizedBox(
                                            //   width: MediaQuery.of(context).size.width * 0.6,
                                            //   height: 16.0,
                                            //   child: AutoSizeText(
                                            //     _replyMessage == null ? '' : _replyMessage!,
                                            //     style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0, letterSpacing: 0.2),
                                            //     maxLines: 1,
                                            //     minFontSize: 12.0,
                                            //     overflow: TextOverflow.ellipsis,
                                            //   ),
                                            // ),
                                            const SizedBox(
                                              width: 5.0,
                                            ),
                                            Container(
                                              width: 40.0,
                                              decoration: const BoxDecoration(
                                                color: Color(0xffa43131),
                                                borderRadius: BorderRadius.only(topRight: Radius.circular(5.0)),
                                              ),
                                              child: InkWell(
                                                borderRadius: const BorderRadius.only(topRight: Radius.circular(5.0)),
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
                                            )
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
                                          cursorColor: Colors.white70,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5!
                                              .copyWith(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.white),
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
                                                  return ScaleTransition(scale: animation, child: child);
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
                  margin: const EdgeInsets.only(top: 8.0, left: 5.0),
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 20.0),
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
                              child: AutoSizeText(widget.mgroup.sentAddr!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  minFontSize: 16.0,
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.headline1!.copyWith(
                                        fontSize: 24.0,
                                        color: Colors.white.withOpacity(0.85),
                                      )),
                            ),
                            AvatarPicker(
                              userID: widget.mgroup.sentAddressOrignal,
                              size: 50.0,
                              color: const Color(0xFF22304D),
                              padding: 2.0,
                              avatarColor: Colors.white54,
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                          ],
                        ),
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
    mBlock.refreshMessages(widget.mgroup.sentAddressOrignal!);
    Future.delayed(const Duration(milliseconds: 500), () {
      _running = true;
    });
  }

  Widget _sendIcon() {
    return const Icon(
      Icons.send,
      size: 30,
      color: Colors.white70,
      key: ValueKey<int>(0),
    );
  }

  Widget _tipIcon() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Container(
        padding: const EdgeInsets.all(5.0),
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5.0)), color: Colors.white10),
        child: Image.asset(
          "images/logo_send.png",
          color: Colors.white70,
          key: const ValueKey<int>(1),
        ),
      ),
    );
  }

  Widget _sendWait() {
    return const SizedBox(
      width: 30,
      height: 30,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        key: ValueKey<int>(2),
        color: Colors.white,
      ),
    );
  }
}
