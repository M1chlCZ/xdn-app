
import 'package:flutter/material.dart';


class OvalButton extends StatelessWidget {
  final double height;
  final double width;
  final Color? color;
  final VoidCallback?  onTap;
  final Icon? icon;
  final AnimatedIcon? animIcon;
  final Color? splashColor;
  final Image? imageIcon;

  const OvalButton({Key? key, required this.height, required this.width, this.color, this.onTap, this.icon, this.imageIcon, this.splashColor, this.animIcon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: Size(height, width), // labelLarge width and height

      child: ClipOval(
        child: Material(
          color: color, // labelLarge color
          child: InkWell(
            splashColor: splashColor, // splash color
            onTap: onTap, // labelLarge pressed
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  animIcon == null ? Container() : animIcon!,
                  icon == null ? Container() : icon! ,
                  imageIcon == null ? Container() : imageIcon!,
                  // icon
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
