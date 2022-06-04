import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:digitalnote/support/BackgroundArc.dart';

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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF323A57),
            Color(0xFF222B46)],
              begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
        )
      ),
      // color: const Color(0xFF323D62),
    );
  }
}
// FF323D62
// 0xFF222B46
