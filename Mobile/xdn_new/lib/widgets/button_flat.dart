import 'package:flutter/material.dart';

class FlatCustomButton extends StatelessWidget {
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback?  onTap;
  final VoidCallback?  onLongPress;
  final Icon? icon;
  final AnimatedIcon? animIcon;
  final Color? splashColor;
  final Image? imageIcon;
  final Widget? child;
  final double? height;
  final double? width;
  final EdgeInsets? padding;
  final double? borderWidth;
  final CrossAxisAlignment alignment;

  const FlatCustomButton({super.key, this.color, this.onTap, this.icon, this.imageIcon, this.splashColor, this.animIcon, this.radius = 4.0, this.child, this.borderColor, this.height, this.width, this.padding, this.borderWidth, this.onLongPress, this.alignment = CrossAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    return _getContainer(
      height,
      width,
      decoration: BoxDecoration(
        color: color,
        border: borderColor != null ? Border.all(color: borderColor!, width: borderWidth ?? 1.5) : null,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: Material(
          color: color, // labelLarge color
          child: InkWell(
            // highlightColor: splashColor!.withOpacity(0.5),
            splashColor: splashColor ?? Colors.white30,
            highlightColor: splashColor ?? Colors.white30,// splash color
            onTap: onTap,
            onLongPress: onLongPress,// labelLarge pressed
            child: Container(
              padding: padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: alignment,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  animIcon ?? Container(),
                  icon ?? Container(),
                  imageIcon ?? Container(),
                  child ?? Container(), // icon
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container _getContainer(double? height, double? width, {required BoxDecoration decoration, required Widget child}) {
    if (height != null) {
      assert(width != null);
      return Container(
        height: height,
        width: width,
        decoration: decoration,
        child: child,
      );
    } else {
      return Container(
        decoration: decoration,
        child: child,
      );
    }
  }
}
