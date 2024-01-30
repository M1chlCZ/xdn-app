import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/barcode_scanner.dart';
import 'package:digitalnote/widgets/button_neu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/AppDatabase.dart';
import '../support/CardHeader.dart';
import '../models/Contact.dart';
import '../support/Dialogs.dart';
import '../support/NetInterface.dart';
import '../support/RoundButton.dart';
import '../widgets/backgroundWidget.dart';

class MessageComposeScreen extends StatefulWidget {
  final Function(String addr)? func;
  final Contact? cont;

  const MessageComposeScreen({super.key, this.func, this.cont});

  @override
  MessageComposeScreenState createState() => MessageComposeScreenState();
}

class MessageComposeScreenState extends State<MessageComposeScreen> {
  final TextEditingController _controllerAddress = TextEditingController();
  final TextEditingController _controllerMessage = TextEditingController();
  Contact? _recipient;
  var _send = true;

  @override
  void initState() {
    super.initState();
    _setRecipient();
  }

  void _setRecipient() {
    if (widget.cont != null) {
      _recipient = widget.cont;
      _controllerAddress.text = _recipient!.getName()!;
    }
  }

  Future<void> _sendMessage() async {
    if (!_send) return;
    if (_recipient == null && _controllerAddress.text == "") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.message_recipient_missing),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        elevation: 5.0,
      ));
      return;
    }
    if (_controllerMessage.text == "") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.message_missing),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        elevation: 5.0,
      ));
      return;
    }
    _send = false;
    var address = _recipient == null ? _controllerAddress.text : _recipient!.getAddr();
    FocusScope.of(context).unfocus();
    Dialogs.openWaitBox(context);
    await NetInterface.sendMessage(address!, _controllerMessage.text.trimRight(), 0);
    Future.delayed(const Duration(milliseconds: 1000), () {
      Navigator.of(context).pop();
    }).then((value) => Navigator.of(context).pop(address));
  }

  void _openQRScanner() async {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
      return BarcodeScanner(
        scanResult: (String s) {
          _controllerAddress.text = s;
        },
      );
    }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        image: "messageicon.png",
      ),
      Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
              child: Column(children: [
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
                      child: AutoSizeText(AppLocalizations.of(context)!.message_new,
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
              padding: const EdgeInsets.only(top: 15.0, left: 20.0, bottom: 10.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32.0), topRight: Radius.circular(32.0)),
                color: const Color(0xFF22283A).withOpacity(0.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Flexible(
                  child: FractionallySizedBox(
                    widthFactor: 0.95,
                    child: SizedBox(
                      height: 45,
                      child: TypeAheadField(
                        suggestionsBoxDecoration: SuggestionsBoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: const Color(0xFF22283A).withOpacity(0.5),
                        ),
                        noItemsFoundBuilder: (context) {
                          return const SizedBox(width: 0, height: 0);
                        },
                        textFieldConfiguration: TextFieldConfiguration(
                          maxLines: 1,
                          controller: _controllerAddress,
                          autofocus: false,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                          decoration: InputDecoration(
                              filled: true,
                              hoverColor: Theme.of(context).cardColor,
                              focusColor: Theme.of(context).cardColor,
                              fillColor: const Color(0xFF22283A).withOpacity(0.5),
                              hintStyle: GoogleFonts.montserrat(fontStyle: FontStyle.normal, color: Colors.white70),
                              labelText: AppLocalizations.of(context)!.message_choose_recipient,
                              labelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: const Color(0xFF22283A).withOpacity(0.1), width: 2.0),
                                  borderRadius: const BorderRadius.all(Radius.circular(10.0))),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: const Color(0xFF22263A).withOpacity(0.1), width: 2.0),
                                  borderRadius: const BorderRadius.all(Radius.circular(10.0)))),
                        ),
                        suggestionsCallback: (pattern) async {
                          return await AppDatabase().searchContact(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          var cont = suggestion as Contact?;
                          return Column(
                            children: [
                              ListTile(
                                tileColor: Colors.transparent,
                                title: SizedBox(
                                  width: 150,
                                  child: AutoSizeText(
                                    cont!.getName()!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                          color: Colors.white70,
                                        ),
                                  ),
                                ),
                                subtitle: SizedBox(
                                  width: 150,
                                  child: AutoSizeText(
                                    cont.getAddr()!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: SizedBox(
                                  height: 1,
                                  child: Container(color: Colors.white.withOpacity(0.2)),
                                ),
                              )
                            ],
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          _recipient = suggestion;
                          _controllerAddress.text = _recipient!.getName()!;
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15.0, top: 1.0),
                  child: RoundButton(
                      height: 50,
                      width: 50,
                      color: const Color(0xFF22283A).withOpacity(0.1),
                      onTap: () {
                        _openQRScanner();
                      },
                      splashColor: Colors.white70,
                      icon: const Icon(
                        Icons.qr_code,
                        size: 40,
                        color: Colors.white70,
                      )),
                ),
              ]),
            ),
            Container(

                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                decoration: BoxDecoration(
                    color: const Color(0xFF22283A).withOpacity(0.5),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15.0), bottomRight: Radius.circular(15.0))),
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0, bottom: 5.0),
                      child: TextField(
                        autofocus: false,
                        textCapitalization: TextCapitalization.sentences,
                        controller: _controllerMessage,
                        keyboardType: TextInputType.multiline,
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(720),
                        ],
                        textAlign: TextAlign.left,
                        textAlignVertical: TextAlignVertical.top,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16.0),
                        decoration: const InputDecoration(
                          hintText: "Type your message here",
                          hintStyle: TextStyle(color: Colors.white70),
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
                    ))),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: NeuButton(
                    height: 40,
                    width: double.infinity,
                    color: Colors.green,
                    child: Text(AppLocalizations.of(context)!.send),
                    onTap: () {
                      _sendMessage();
                    },
                  ),
                )
          ])))
    ]);
  }
}

// onTap: () {
// _sendMessage();
// },
