import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../support/ColorScheme.dart';

class DialogBody extends StatefulWidget {
  final VoidCallback? onTap;
  final String header;
  final String buttonLabel;
  final String buttonCancelLabel;
  final Widget child;
  final bool oneButton;

  const DialogBody({
    Key? key,
    this.onTap,
    required this.header,
    required this.child,
    required this.buttonLabel,
    this.oneButton = false,
    this.buttonCancelLabel = 'Cancel',
  }) : super(key: key);

  @override
  _DialogBodyState createState() => _DialogBodyState();
}

class _DialogBodyState extends State<DialogBody> {
  String _cancelButton = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _cancelButton = AppLocalizations.of(context)!.cancel;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Theme.of(context).konjHeaderColor,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).konjHeaderColor),
            borderRadius: const BorderRadius.all(Radius.circular(15.0))),
        contentPadding: const EdgeInsets.only(top: 0.01),
        content: SizedBox(
            width: 400.0,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
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
                          widget.header,
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
                  widget.child,
                  widget.oneButton
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Expanded(
                                flex: 2,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(15.0),
                                    bottomRight: Radius.circular(15.0),
                                  ),
                                  child: Material(
                                    color: Colors.deepPurpleAccent
                                        .withOpacity(0.4),
                                    child: InkWell(
                                      splashColor: Colors.white,
                                      customBorder: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(15.0),
                                        bottomRight: Radius.circular(15.0),
                                      )),
                                      onTap: () {
                                        widget.onTap!();
                                        // Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 18.0, bottom: 18.0),
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(15.0),
                                            bottomRight: Radius.circular(15.0),
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 50,
                                          child: AutoSizeText(
                                            widget.buttonLabel,
                                            maxLines: 1,
                                            minFontSize: 12.0,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline6!
                                                .copyWith(
                                                    fontSize: 18.0,
                                                    color: Colors.white70),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ])
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Expanded(
                                flex: 2,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(15.0)),
                                  child: Material(
                                    color: Colors.deepPurpleAccent
                                        .withOpacity(0.4),
                                    child: InkWell(
                                      splashColor: Colors.white,
                                      customBorder: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                              bottomLeft:
                                                  Radius.circular(15.0))),
                                      onTap: () {
                                        widget.onTap!();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 20.0, bottom: 20.0),
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(15.0),
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 50,
                                          child: AutoSizeText(
                                            widget.buttonLabel,
                                            maxLines: 1,
                                            minFontSize: 12.0,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline6!
                                                .copyWith(
                                                    color: Colors.white,
                                                    fontSize: 16.0),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      bottomRight: Radius.circular(15.0)),
                                  child: Material(
                                    color: Colors.white.withOpacity(0.2),
                                    child: InkWell(
                                      splashColor: Colors.white,
                                      customBorder: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                              bottomRight:
                                                  Radius.circular(15.0))),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 20.0, bottom: 20.0),
                                        decoration: const BoxDecoration(
                                          // color: Colors.red,
                                          borderRadius: BorderRadius.only(
                                              bottomRight:
                                                  Radius.circular(15.0)),
                                        ),
                                        child: Text(
                                          _cancelButton,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                  color: Colors.white,
                                                  fontSize: 16.0),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ])
                ])));
  }
}
