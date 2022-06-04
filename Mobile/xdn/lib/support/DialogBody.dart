import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../support/ColorScheme.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/widgets/button_neu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DialogBody extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final String? header;
  final String buttonLabel;
  final String buttonCancelLabel;
  final Widget child;
  final bool oneButton;
  final bool noButtons;
  final double? radius;

  const DialogBody({
    Key? key,
    this.onTap,
    this.onCancel,
    this.radius,
    this.header,
    required this.child,
    required this.buttonLabel,
    this.oneButton = false,
    this.buttonCancelLabel = 'Cancel', this.noButtons = false,
  }) : super(key: key);

  @override
  DialogBodyState createState() => DialogBodyState();
}

class DialogBodyState extends State<DialogBody> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).canvasColor),
            borderRadius:  BorderRadius.all(Radius.circular(widget.radius ?? 5.0))),
        contentPadding: const EdgeInsets.only(top: 0.01),
        content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Visibility(
                    visible: widget.header != null,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10.0, left: 10.0, right: 10.0, bottom: 5.0),
                          decoration: const BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15.0),
                                  topRight: Radius.circular(15.0))),
                          child: Center(
                            child: SizedBox(
                              width: 380,
                              child: AutoSizeText(
                                widget.header ?? '',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 8.0,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline6!
                                    .copyWith(fontSize: 22.0, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                        const Divider(
                          color: Colors.grey,
                          height: 2.0,
                        ),
                      ],
                    ),
                  ),
                  widget.child,
                  !widget.noButtons ?
                  widget.oneButton
                      ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeuButton(
                            width: 100,
                            height: 40,
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'OK',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4!
                                    .copyWith(color: Colors.white),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        ]),
                  )
                      : Padding(
                    padding:
                    const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NeuButton(
                            width: 100,
                            height: 40,
                            onTap: () {
                              widget.onTap == null ? Navigator.of(context).pop() : widget.onTap!();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                AppLocalizations.of(context)!.yes,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4!
                                    .copyWith(color: Colors.white),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                          NeuButton(
                            width: 100,
                            height: 40,
                            onTap: () {
                              widget.onCancel == null ? Navigator.of(context).pop() : widget.onCancel!();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                AppLocalizations.of(context)!.cancel,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4!
                                    .copyWith(color: Colors.white),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        ]),
                  ) : Container(),
                ])));
  }
}

