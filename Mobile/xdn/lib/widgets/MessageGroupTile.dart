import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/MessageGroup.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';

import '../support/ColorScheme.dart';
import '../support/SimpleRichText.dart';

class MessageGroupTile extends StatefulWidget {
  final MessageGroup mgroup;
  final void Function(String addr)? func;
  final void Function(MessageGroup mesgroup)? callbackMgroup;
  final VoidCallback func3;

  const MessageGroupTile({Key? key, required this.mgroup, this.func, this.callbackMgroup, required this.func3}) : super(key: key);

  @override
  MessageGroupTileState createState() => MessageGroupTileState();
}

class MessageGroupTileState extends State<MessageGroupTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(15.0)),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(top: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: const Color(0xFF181C2A).withOpacity(0.3),
        child: InkWell(
          splashColor: Colors.white.withOpacity(0.8),
          highlightColor: Colors.white,
          onTap: () {
            widget.callbackMgroup!(widget.mgroup);
          },
          onLongPress: () async {
            Dialogs.openMessageContactAddBox(context, widget.mgroup.sentAddressOrignal!).then((value) => widget.func3());
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Row(
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                          color: widget.mgroup.unread! > 0 ? Colors.lightGreenAccent : const Color(0xFF22304D),
                        )),
                    Center(
                      child: SizedBox(width: 57, height: 57, child:
                      AvatarPicker(
                        borderRadius: 15.0,
                          avatarColor: Colors.white54,
                          color: const Color(0xFF22304D),
                          userID: widget.mgroup.sentAddressOrignal)),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 15.0, top: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 200,
                              height: 20,
                              child: AutoSizeText(
                                widget.mgroup.sentAddr!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 16.0,
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16.0),
                              ),
                            ),
                            Text(
                              getDate(widget.mgroup.lastReceivedMessage!),
                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, right: 0.0, bottom: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.64,
                                  height: 20,
                                  child: SimpleRichText(
                                    widget.mgroup.text!,
                                    maxLines: 1,
                                    textOverflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 14.0),
                                  )
                                  // child: AutoSizeText(
                                  //   widget.mgroup.text,
                                  //   maxLines: 1,
                                  //   overflow: TextOverflow.ellipsis,
                                  //   minFontSize: 14.0,
                                  //   style: TextStyle(
                                  //       color: Colors.white70,
                                  //       fontWeight: FontWeight.normal,
                                  //       fontSize: 14.0),
                                  // ),
                                  ),
                              Opacity(
                                // opacity: widget.mgroup.unread! > 0 ? 1.0 : 0.0,
                                opacity: 0,
                                child: ClipOval(
                                  child: Container(
                                    height: 24,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black45.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(2, 5), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.mgroup.unread.toString(),
                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 16.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String getDate(String dateTime) {
  DateFormat format;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var date = DateTime.parse(dateTime).toLocal();
  final checkdate = DateTime(date.year, date.month, date.day);
  if (checkdate == today) {
    format = DateFormat.jm(Platform.localeName);
  } else {
    format = DateFormat.MMMEd(Platform.localeName);
  }
  return format.format(date);
}
