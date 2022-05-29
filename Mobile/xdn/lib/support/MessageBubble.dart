import 'dart:io';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:digitalnote/support/Swipeable.dart';
import 'package:url_launcher/url_launcher.dart';

import '../support/ColorScheme.dart';
import '../support/SimpleRichText.dart';
import 'AppDatabase.dart';
import 'Message.dart';
import 'NetInterface.dart';

class MessageBubble extends StatefulWidget {
  final Message messages;
  final bool userMessage;
  final Function(String, int) replyCallback;

  const MessageBubble({Key? key, required this.messages, required this.userMessage, required this.replyCallback}) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with TickerProviderStateMixin {
  final RegExp regexEmoji = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
  String? _replyText;
  bool _rb = false;
  Widget? _heart;
  Widget? _heartLeft;
  double _textSize = 16.0;

  String _getMeDate(String d) {
    DateFormat format;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var date = DateTime.parse(d).toLocal();
    final checkdate = DateTime(date.year, date.month, date.day);
    if (checkdate == today) {
      format = DateFormat.jm(Platform.localeName);
      return format.format(date);
    } else {
      format = DateFormat.MMMEd(Platform.localeName);
      return format.format(date) + " " + DateFormat.jm(Platform.localeName).format(date);
    }
  }

  bool _checkForLink(String message) {
    if (message.contains(RegExp(r'https', caseSensitive: false))) {
      return true;
    } else if (message.contains(RegExp(r'http', caseSensitive: false))) {
      return true;
    } else if (message.contains(RegExp(r'www', caseSensitive: false))) {
      return true;
    } else {
      return false;
    }
  }

  bool _checkForTip(String d) {
    if (d.contains(AppLocalizations.of(context)!.message_reply_to)) {
      if (d.contains("KONJ")) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _heart = _emptyHeart();
    _heartLeft = _emptyHeartLeft();
    Future.delayed(const Duration(milliseconds: 50), () {
      _switchWidget(widget.messages.likes!);
    });
    List<String> wordList = widget.messages.text!.split(" ");
    if (regexEmoji.hasMatch(widget.messages.text!) && wordList.length == 1) {
      _textSize = 40.0;
    }
    _checkReplies();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _checkReplies() async {
    if (widget.messages.idReply != 0) {
      _replyText = await AppDatabase().getReplyText(widget.messages.idReply!);
      setState(() {
        _rb = true;
      });
    } else {
      _rb = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _switchWidget(widget.messages.likes!);
    return widget.userMessage == true ? bubbleRight() : bubbleLeft();
  }

  Widget bubbleLeft() {
    return GestureDetector(
      onDoubleTap: () async {
        int i = await NetInterface.updateLikes(widget.messages.id!);
        _switchWidget(i);
        setState(() {
          widget.messages.likes = i;
        });
      },
      onLongPress: () {
        // print(widget.messages.text!.length);
        Clipboard.setData(ClipboardData(text: widget.messages.text));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.message_copy),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      },
      child: Swipeable(
        threshold: 40.0,
        onSwipeRight: () {
          widget.replyCallback(widget.messages.text!, widget.messages.id!);
        },
        background: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(
              Icons.reply_sharp,
              color: Colors.white70,
              size: 30.0,
            ),
          ],
        ),
        child: Bubble(
          margin: const BubbleEdges.only(top: 10),
          radius: const Radius.circular(15.0),
          alignment: Alignment.topLeft,
          nip: BubbleNip.no,
          color: _checkForTip(widget.messages.text!) == true ? Colors.green : const Color.fromRGBO(224, 224, 224, 1.0),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rb == true
                      ? IntrinsicWidth(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Text(
                                        AppLocalizations.of(context)!.message_reply_to+':',
                                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, color: Colors.black26),
                                        textAlign: TextAlign.start,
                                      )),
                                  const SizedBox(
                                    height: 1.0,
                                  ),
                                  Flexible(
                                    child: SimpleRichText(_replyText!,
                                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, color: Colors.black87, fontStyle: FontStyle.italic),
                                        textOverflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 1.0,
                                  minWidth: 15.0,
                                  maxHeight: 1.0,
                                  maxWidth: 100.0,
                                ),
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(color: Colors.black38),
                                ),
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(
                          height: 1,
                          width: 1,
                        ),
                  Padding(
                    padding: const EdgeInsets.only(left: 0.0, right: 60.0),
                    child: _checkForLink(widget.messages.text!) == false
                        ? SimpleRichText(
                            widget.messages.text!,
                            textAlign: TextAlign.left,
                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: _textSize, color: const Color.fromRGBO(31, 30, 30, 1.0)),
                          )
                        : SelectableLinkify(
                            onOpen: (link) async {
                              if (await canLaunch(link.url)) {
                                await launch(link.url);
                              } else {
                                print('Could not launch $link');
                              }
                            },
                            text: widget.messages.text!,
                            textAlign: TextAlign.left,
                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 16.0, color: const Color.fromRGBO(31, 30, 30, 1.0))),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            reverseDuration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.bounceOut,
                            switchOutCurve: Curves.bounceOut,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(child: child, scale: animation);
                            },
                            child: _heartLeft,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(_getMeDate(widget.messages.lastMessage!),
                              textAlign: TextAlign.right, style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, color: const Color.fromRGBO(31, 30, 30, 1.0))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bubbleRight() {
    return GestureDetector(
      onDoubleTap: () async {
        int i = await NetInterface.updateLikes(widget.messages.id!);
        _switchWidget(i);
        setState(() {
          widget.messages.likes = i;
        });
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: widget.messages.text));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.message_copy),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      },
      child: Swipeable(
        threshold: 40.0,
        onSwipeLeft: () {
          widget.replyCallback(widget.messages.text!, widget.messages.id!);
        },
        background: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Icon(
              Icons.reply_sharp,
              color: Colors.white70,
              size: 30.0,
            ),
          ],
        ),
        child: Bubble(
          margin: const BubbleEdges.only(top: 10),
          alignment: widget.userMessage == true ? Alignment.topRight : Alignment.topLeft,
          radius: const Radius.circular(15.0),
          nip: BubbleNip.no,
          color: _checkForTip(widget.messages.text!) == true ? Colors.green : Theme.of(context).konjHeaderColor,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: widget.userMessage == false ? CrossAxisAlignment.end : CrossAxisAlignment.end,
                children: [
                  _rb == true
                      ? IntrinsicWidth(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Text(
                                        AppLocalizations.of(context)!.message_reply_to + ':',
                                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, color: Colors.white30),
                                      )),
                                  const SizedBox(
                                    height: 1.0,
                                  ),
                                  Flexible(
                                    child: SimpleRichText(_replyText!,
                                        style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 12.0, color: Colors.white54, fontStyle: FontStyle.italic),
                                        textOverflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 1.0,
                                  minWidth: 15.0,
                                  maxHeight: 1.0,
                                  maxWidth: 100.0,
                                ),
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(
                          height: 1,
                          width: 1,
                        ),
                  _checkForLink(widget.messages.text!) == false
                      ? SimpleRichText(widget.messages.text!,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline5!.copyWith(
                                fontSize: _textSize,
                                color: Colors.white.withOpacity(0.9),
                              ))
                      : SelectableLinkify(
                          onOpen: (link) async {
                            if (await canLaunch(link.url)) {
                              await launch(link.url);
                            } else {
                              print('Could not launch $link');
                            }
                          },
                          text: widget.messages.text!,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline5!.copyWith(
                                fontSize: 16.0,
                              )),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          reverseDuration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.bounceOut,
                          switchOutCurve: Curves.bounceOut,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return ScaleTransition(child: child, scale: animation);
                          },
                          child: _heart,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(_getMeDate(widget.messages.lastMessage!),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.headline5!.copyWith(
                                  fontSize: 12.0,
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyHeart() {
    return Image.asset(
      "images/heart.png",
      height: 15,
      width: 15,
      fit: BoxFit.fitHeight,
      color: Colors.white70,
      key: const ValueKey<int>(0),
    );
  }

  Widget _emptyHeartLeft() {
    return Image.asset(
      "images/heart.png",
      height: 15,
      width: 15,
      fit: BoxFit.fitHeight,
      color: Colors.black54,
      key: const ValueKey<int>(3),
    );
  }

  Widget _fullHeart() {
    return Image.asset(
      "images/filledheart.png",
      height: 15,
      width: 15,
      fit: BoxFit.fitHeight,
      key: const ValueKey<int>(1),
    );
  }

  void _switchWidget(int i) {
    if (i == 0) {
      setState(() {
        _heart = _emptyHeart();
        _heartLeft = _emptyHeartLeft();
      });
    } else {
      setState(() {
        _heart = _fullHeart();
        _heartLeft = _fullHeart();
      });
    }
  }
}
