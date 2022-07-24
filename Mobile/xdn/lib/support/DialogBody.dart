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
  final String? buttonLabel;
  final String buttonCancelLabel;
  final Widget child;
  final bool oneButton;
  final bool noButtons;
  final double? radius;
  final double? dialogWidth;

  const DialogBody({
    Key? key,
    this.onTap,
    this.onCancel,
    this.radius,
    this.header,
    required this.child,
    this.buttonLabel,
    this.oneButton = false,
    this.buttonCancelLabel = 'Cancel', this.noButtons = false, this.dialogWidth,
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
      insetPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        backgroundColor: const Color(0xFF363D4E),
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF363D4E)),
            borderRadius:  BorderRadius.all(Radius.circular(widget.radius ?? 15.0))),
        contentPadding: const EdgeInsets.only(top: 0.01),
        content: SizedBox(
            width: widget.dialogWidth ?? MediaQuery.of(context).size.width *0.8,
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
                                    .bodyText1!
                                    .copyWith(fontSize: 22.0, color: Colors.white70, fontWeight: FontWeight.bold),
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
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 40,
                        child: TextButton(
                          clipBehavior: Clip.antiAlias,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.all(3.0),
                              minimumSize: const Size(20, 20),
                              alignment: Alignment.center,
                              backgroundColor: Colors.black.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(15.0),
                              )),
                            child: AutoSizeText(
                              'OK',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1!
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.normal),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              minFontSize: 8.0,
                            ),
                          ),),
                        ]),
                  )
                      : Padding(
                    padding:
                    const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 120.0,
                            height: 40,
                            child: TextButton(
                              clipBehavior: Clip.antiAlias,
                            onPressed: () {
                              widget.onTap == null ? Navigator.of(context).pop() : widget.onTap!();
                            },
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.all(3.0),
                                  minimumSize: const Size(20, 20),
                                  alignment: Alignment.center,
                                  backgroundColor: Colors.black.withOpacity(0.05),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(color: Colors.white30),
                                    borderRadius: BorderRadius.circular(15.0),
                                  )),
                            child: AutoSizeText(
                             widget.buttonLabel ?? AppLocalizations.of(context)!.yes,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1!
                                  .copyWith(color: Colors.white70, fontWeight: FontWeight.normal),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              minFontSize: 8.0,
                            ),
                          ),),
                          SizedBox(
                            height: 40,
                            width: 120.0,
                            child: TextButton(
                              clipBehavior: Clip.antiAlias,
                              onPressed: () {
                              widget.onCancel == null ? Navigator.of(context).pop() : widget.onCancel!();
                            },
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                                  minimumSize: const Size(20, 20),
                                  alignment: Alignment.center,
                                  backgroundColor: Colors.black.withOpacity(0.05),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(color: Colors.white30),
                                    borderRadius: BorderRadius.circular(15.0),
                                  )),
                            child: AutoSizeText(
                              AppLocalizations.of(context)!.cancel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1!
                                  .copyWith(color: Colors.white70, fontWeight: FontWeight.normal),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              minFontSize: 8.0,
                            ),
                          ),
                          )]),
                  ) : Container(),
                ]
            )));
  }
}

