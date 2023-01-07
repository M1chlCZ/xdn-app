

import 'package:flutter/material.dart';

class BackgroundWidget extends StatefulWidget {
  final bool mainMenu;
  final bool hasImage;
  final String? image;
  final bool arc;

  const BackgroundWidget({Key? key, this.mainMenu = false, this.hasImage = true, this.image, this.arc = false}) : super(key: key);

  @override
  BackgroundWidgetState createState() => BackgroundWidgetState();
}

class BackgroundWidgetState extends State<BackgroundWidget> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Container(
      width: width,
      height: height,
      decoration:  BoxDecoration(
        gradient:  RadialGradient(
          // stops: [0.1, 0.9],
          center: Alignment(widget.mainMenu ?  0.9 : 1.5, 0.0),
          colors: [
            widget.mainMenu ? const Color(0xFF1C2952) :
            const Color(0xFF222C50),
            const Color(0xFF323A57)
          ],
          radius: 1.0,
        ),
      ),
      // color: const Color(0xFF323D62),
    );
  }
}