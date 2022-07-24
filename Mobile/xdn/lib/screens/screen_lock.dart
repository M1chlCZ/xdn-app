import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

typedef DeleteCode = void Function();
typedef PassCodeVerify = Future<bool> Function(List<int> passcode);

class LockScreen extends StatefulWidget {
  /// Password on success method
  final VoidCallback onSuccess;

  /// Password finger function for auth
  final VoidCallback? fingerFunction;

  /// Password finger verify for auth
  final bool? fingerVerify;

  /// screen title
  final String title;

  /// Pass length
  final int passLength;

  /// Wrong password dialog
  final bool? showWrongPassDialog;

  /// Showing finger print area
  final bool? showFingerPass;

  /// Wrong password dialog title
  final String? wrongPassTitle;

  /// Wrong password dialog content
  final String? wrongPassContent;

  /// Wrong password dialog button text
  final String? wrongPassCancelButtonText;

  /// Background image
  final String? bgImage;

  /// Color for numbers
  final Color? numColor;

  /// Finger print image
  final Widget? fingerPrintImage;

  /// border color
  final Color? borderColor;

  /// foreground color
  final Color? foregroundColor;

  /// Password verify
  final PassCodeVerify passCodeVerify;

  /// BackGround color
  final Color? backgroundColor;

  /// Lock Screen constructer
  const LockScreen({
    Key? key,
    required this.onSuccess,
    required this.title,
    this.borderColor,
    this.foregroundColor = Colors.transparent,
    required this.passLength,
    required this.passCodeVerify,
    this.fingerFunction,
    this.fingerVerify = false,
    this.showFingerPass = false,
    this.bgImage,
    this.numColor = Colors.black,
    this.fingerPrintImage,
    this.showWrongPassDialog = false,
    this.wrongPassTitle,
    this.wrongPassContent,
    this.wrongPassCancelButtonText,
    this.backgroundColor,
  })  : assert(passLength <= 8),
        assert(bgImage != null),
        assert(borderColor != null),
        assert(foregroundColor != null),
        super(key: key);

  @override
  LockScreenState createState() => LockScreenState();

}

class LockScreenState extends State<LockScreen> {
  var _currentCodeLength = 0;
  final _inputCodes = <int>[];
  var _currentState = 0;
  Color circleColor = Colors.white;

  _onCodeClick(int code) {
    if (_currentCodeLength < widget.passLength) {
      setState(() {
        _currentCodeLength++;
        _inputCodes.add(code);
      });

      if (_currentCodeLength == widget.passLength) {
        widget.passCodeVerify(_inputCodes).then((onValue) {
          if (onValue) {
            setState(() {
              _currentState = 1;
            });
            widget.onSuccess();
          } else {
            _currentState = 2;
            Timer(const Duration(milliseconds: 1000), () {
              setState(() {
                _currentState = 0;
                _currentCodeLength = 0;
                _inputCodes.clear();
              });
            });
            if (widget.showWrongPassDialog!) {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return Center(
                      child: AlertDialog(
                        title: Text(
                          widget.wrongPassTitle!,
                          style: const TextStyle(fontFamily: "Open Sans"),
                        ),
                        content: Text(
                          widget.wrongPassContent!,
                          style: const TextStyle(fontFamily: "Open Sans"),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              widget.wrongPassCancelButtonText!,
                              style: const TextStyle(color: Colors.blue),
                            ),
                          )
                        ],
                      ),
                    );
                  });
            }
          }
        });
      }
    }
  }

  _fingerPrint() {
    if (widget.fingerVerify!) {
      widget.onSuccess();
    }
  }

  _deleteCode() {
    setState(() {
      if (_currentCodeLength > 0) {
        _currentState = 0;
        _currentCodeLength--;
        _inputCodes.removeAt(_currentCodeLength);
      }
    });
  }

  _deleteAllCode() {
    setState(() {
      if (_currentCodeLength > 0) {
        _currentState = 0;
        _currentCodeLength = 0;
        _inputCodes.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 200), () {
      _fingerPrint();
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Container(
            color: widget.backgroundColor ?? Theme.of(context).canvasColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: <Widget>[
                      Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        decoration:
                            BoxDecoration(color: Theme.of(context).canvasColor
                                // image: DecorationImage(
                                //   image: AssetImage(widget.bgImage!),
                                //   fit: BoxFit.cover,
                                //   colorFilter: ColorFilter.mode(
                                //     Colors.grey.shade800,
                                //     BlendMode.hardLight,
                                //   ),
                                // ),
                                ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              height: Platform.isIOS ? 130 : 100,
                            ),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Montserrat"),
                            ),
                            SizedBox(
                              height: Platform.isIOS ? 20 : 30,
                            ),
                            CodePanel(
                              codeLength: widget.passLength,
                              currentLength: _currentCodeLength,
                              borderColor: widget.borderColor,
                              foregroundColor: widget.foregroundColor,
                              deleteCode: _deleteCode,
                              fingerVerify: widget.fingerVerify!,
                              status: _currentState,
                            ),
                          ],
                        ),
                      ),
                      widget.showFingerPass!
                          ? Positioned(
                              top: 10,
                              right: 15,
                              child: GestureDetector(
                                onTap: () {
                                  widget.fingerFunction!();
                                },
                                child: SizedBox(
                                    width: 60.0,
                                    child: widget.fingerPrintImage!),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
                Expanded(
                  flex: Platform.isIOS ? 10 : 8,
                  child: Container(
                    padding: const EdgeInsets.only(left: 0, top: 0),
                    child:
                        NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowIndicator();
                        return true;
                      },
                      child: GridView.count(
                        crossAxisCount: 3,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 0,
                        padding: const EdgeInsets.all(20),
                        children: <Widget>[
                          buildContainerCircle(1),
                          buildContainerCircle(2),
                          buildContainerCircle(3),
                          buildContainerCircle(4),
                          buildContainerCircle(5),
                          buildContainerCircle(6),
                          buildContainerCircle(7),
                          buildContainerCircle(8),
                          buildContainerCircle(9),
                          buildRemoveIcon(Icons.close),
                          buildContainerCircle(0),
                          buildContainerIcon(Icons.arrow_back),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContainerCircle(int number) {
    return Align(
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(
            offset: Offset(-1, -1),
            blurRadius: 4.0,
            color: Color.fromRGBO(134, 134, 134, 0.15),
          ),
          BoxShadow(
            offset: Offset(1, 1),
            blurRadius: 4.0,
            color: Color.fromRGBO(2, 2, 2, 0.85),
          ),
        ]),
        child: ClipOval(
          child: SizedBox(
            height: 75,
            width: 75,
            child: Material(
              color: Theme.of(context).canvasColor,
              child: InkWell(
                splashColor: Colors.white30,
                onTap: () {
                  _onCodeClick(number);
                },
                child: Center(
                  child: Text(
                    number.toString(),
                    style: Theme.of(context).textTheme.headline4!.copyWith(
                        color: widget.numColor,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRemoveIcon(IconData icon) {
    return Align(
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(
            offset: Offset(-1, -1),
            blurRadius: 4.0,
            color: Color.fromRGBO(134, 134, 134, 0.15),
          ),
          BoxShadow(
            offset: Offset(1, 1),
            blurRadius: 4.0,
            color: Color.fromRGBO(2, 2, 2, 0.85),
          ),
        ]),
        child: ClipOval(
          child: SizedBox(
            height: 75,
            width: 75,
            child: Material(
              color: Theme.of(context).canvasColor,
              child: InkWell(
                splashColor: Colors.white30,
                onTap: () {
                  if (0 < _currentCodeLength) {
                    _deleteAllCode();
                  }
                },
                child: Center(
                  child: Icon(
                    icon,
                    size: 30,
                    color: widget.numColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContainerIcon(IconData icon) {
    return Align(
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(
            offset: Offset(-1, -1),
            blurRadius: 4.0,
            color: Color.fromRGBO(134, 134, 134, 0.15),
          ),
          BoxShadow(
            offset: Offset(1, 1),
            blurRadius: 4.0,
            color: Color.fromRGBO(2, 2, 2, 0.85),
          ),
        ]),
        child: ClipOval(
          child: SizedBox(
            height: 75,
            width: 75,
            child: Material(
              color: Theme.of(context).canvasColor,
              child: InkWell(
                splashColor: Colors.white30,
                onTap: () {
                  if (0 < _currentCodeLength) {
                    setState(() {
                      circleColor = Colors.grey.shade300;
                    });
                    Future.delayed(const Duration(milliseconds: 200))
                        .then((func) {
                      setState(() {
                        circleColor = Colors.white;
                      });
                    });
                  }
                  _deleteCode();
                },
                child: Center(
                  child: Icon(
                    icon,
                    size: 30,
                    color: widget.numColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CodePanel extends StatelessWidget {
  final codeLength;
  final currentLength;
  final borderColor;
  final bool? fingerVerify;
  final foregroundColor;
  final H = 30.0;
  final W = 30.0;
  final DeleteCode? deleteCode;
  final int? status;

  const CodePanel(
      {Key? key,
      this.codeLength,
      this.currentLength,
      this.borderColor,
      this.foregroundColor,
      this.deleteCode,
      this.fingerVerify,
      this.status})
      : assert(codeLength > 0),
        assert(currentLength >= 0),
        assert(currentLength <= codeLength),
        assert(deleteCode != null),
        assert(status == 0 || status == 1 || status == 2),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var circles = <Widget>[];
    var color = borderColor;
    int circlePice = 1;

    if (fingerVerify == true) {
      do {
        circles.add(
          SizedBox(
            width: W,
            height: H,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.0),
                color: Colors.green.shade500,
              ),
            ),
          ),
        );
        circlePice++;
      } while (circlePice <= codeLength);
    } else {
      if (status == 1) {
        color = Colors.green.shade500;
      }
      if (status == 2) {
        color = Colors.red.shade500;
      }
      for (int i = 1; i <= codeLength; i++) {
        if (i > currentLength) {
          circles.add(SizedBox(
              width: W,
              height: H,
              child: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.0),
                    color: foregroundColor),
              )));
        } else {
          circles.add(SizedBox(
              width: W,
              height: H,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.0),
                  color: color,
                ),
              )));
        }
      }
    }

    return SizedBox.fromSize(
      size: Size(MediaQuery.of(context).size.width, 30.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox.fromSize(
                size: Size(40.0 * codeLength, H),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: circles,
                )),
          ]),
    );
  }
}

class BgClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height / 1.5);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
