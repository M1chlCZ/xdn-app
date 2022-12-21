import 'package:flutter/material.dart';


class RoundButton extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  final Color? color;
  final VoidCallback?  onTap;
  final Icon? icon;
  final AnimatedIcon? animIcon;
  final Color? splashColor;
  final Image? imageIcon;

  const RoundButton({Key? key, required this.height, required this.width, this.color, this.onTap, this.icon, this.imageIcon, this.splashColor, this.animIcon, this.radius = 10.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: Size(width, height), // labelLarge width and height

      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: Material(
          color: color, // labelLarge color
          child: InkWell(
            splashColor: splashColor, // splash color
            onTap: onTap, // labelLarge pressed
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
    );
  }
}
