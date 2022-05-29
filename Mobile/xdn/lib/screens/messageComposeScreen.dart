import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:permission_handler/permission_handler.dart';

import '../support/AppDatabase.dart';
import '../support/CardHeader.dart';
import '../support/ColorScheme.dart';
import '../support/Contact.dart';
import '../support/Dialogs.dart';
import '../support/NetInterface.dart';
import '../support/QCodeScanner.dart';
import '../support/RoundButton.dart';
import '../widgets/backgroundWidget.dart';

class MessageComposeScreen extends StatefulWidget {
  final Function(String addr)? func;
  final Contact? cont;

  const MessageComposeScreen({Key? key, this.func, this.cont}) : super(key: key);

  @override
  _MessageComposeScreenState createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
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
    var _address = _recipient == null ? _controllerAddress.text : _recipient!.getAddr();
    FocusScope.of(context).unfocus();
    Dialogs.openWaitBox(context);
    await NetInterface.sendMessage(_address!, _controllerMessage.text.trimRight(), 0);
    Future.delayed(const Duration(milliseconds: 1000), () {
      Navigator.of(context).pop();
    }).then((value) => Navigator.of(context).pop(_address));
  }

  void _openQRScanner() async {
    FocusScope.of(context).unfocus();

    Future.delayed(const Duration(milliseconds: 200), () async {
      var status = await Permission.camera.status;
      if (await Permission.camera.isPermanentlyDenied) {
        await Dialogs.openAlertBoxReturn(context, AppLocalizations.of(context)!.warning, AppLocalizations.of(context)!.camera_perm);
        openAppSettings();
      } else if (status.isDenied) {
        var r = await Permission.camera.request();
        if (r.isGranted) {
          Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
            return QScanWidget(
              scanResult: (String s) {
                _controllerAddress.text = s;
              },
            );
          }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          }));
        }
      } else {
        Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
          return QScanWidget(
            scanResult: (String s) {
              _controllerAddress.text = s;
            },
          );
        }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        }));
      }
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
        body: SafeArea(
          child: Column(children: [
            CardHeader(
              title: AppLocalizations.of(context)!.message_new,
              backArrow: true,
            ),
            Container(
              margin: const EdgeInsets.only(left: 5.0, right: 5.0),
              padding: const EdgeInsets.only(top: 15.0, left: 20.0, bottom: 10.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32.0), topRight: Radius.circular(32.0)),
                color: Theme.of(context).konjHeaderColor,
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
                          color: Theme.of(context).konjCardColor,
                        ),
                        noItemsFoundBuilder: (context) {
                          return const SizedBox(width: 0, height: 0);
                        },
                        textFieldConfiguration: TextFieldConfiguration(
                          maxLines: 1,
                          controller: _controllerAddress,
                          autofocus: false,
                          style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                          decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.all(8.0),
                              filled: true,
                              hoverColor: Colors.white24,
                              focusColor: Colors.white24,
                              fillColor: Theme.of(context).konjTextFieldHeaderColor,
                              labelText: "",
                              labelStyle: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white54, fontSize: 18.0),
                              hintText: AppLocalizations.of(context)!.message_choose_recipient,
                              hintStyle: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white54, fontSize: 18.0),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white70,
                              ),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0)))),
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
                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(
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
                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(
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
                          _recipient = suggestion as Contact;
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
                      color: Theme.of(context).konjHeaderColor,
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
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                decoration: BoxDecoration(color: Theme.of(context).konjTextFieldHeaderColor, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32.0), bottomRight: Radius.circular(32.0))),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Wrap(children: [
                      Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).konjHeaderColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                      bottomRight: Radius.circular(32.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 5.0, bottom: 5.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            autofocus: false,
                            textCapitalization: TextCapitalization.sentences,
                            controller: _controllerMessage,
                            keyboardType: TextInputType.multiline,
                            inputFormatters: <TextInputFormatter>[
                              LengthLimitingTextInputFormatter(720),
                            ],
                            textAlign: TextAlign.left,
                            style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 16.0),
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
                            padding: const EdgeInsets.only(left:5.0),
                            child: SizedBox(
                              width: 55,
                              height: 55,
                              child: GestureDetector(
                                onTap: () {
                                  _sendMessage();
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return ScaleTransition(child: child, scale: animation);
                                  },
                                  child: const Icon(
                                    Icons.expand_less,
                                    size: 45,
                                    color: Colors.white,
                                    key: ValueKey<int>(1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                      ),
                    ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
