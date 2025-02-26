import 'package:flutter/material.dart';

typedef GetHover = Widget Function(bool value);

class FlatCustomButton extends StatefulWidget {
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
  final GetHover? getHover;

  const FlatCustomButton({Key? key, this.color, this.onTap, this.icon, this.imageIcon, this.splashColor, this.animIcon, this.radius = 4.0, this.child, this.borderColor, this.height, this.width, this.padding, this.borderWidth, this.onLongPress, this.alignment = CrossAxisAlignment.center, this.getHover}) : super(key: key);

  @override
  State<FlatCustomButton> createState() => _FlatCustomButtonState();
}

class _FlatCustomButtonState extends State<FlatCustomButton> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _getContainer(
        widget.height,
        widget.width,
        decoration: BoxDecoration(
          color: widget.color,
          border: widget.borderColor != null ? Border.all(color: widget.borderColor!, width: widget.borderWidth ?? 1.5) : null,
          borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            color: isHover ? widget.splashColor  : widget.color,
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.radius),
              ),
              hoverColor: widget.splashColor,
              // highlightColor: splashColor!.withOpacity(0.5),
              splashColor: widget.splashColor ?? Colors.white30,
              highlightColor: widget.splashColor ?? Colors.white30,// splash color
              onTap: widget.onTap,
              onHover: (val) {
                setState(() {
                  isHover = val;
                });
              },
              onLongPress: widget.onLongPress,// labelLarge pressed
              child: Container(
                padding: widget.padding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: widget.alignment,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    widget.getHover?.call(isHover) ?? Container(),
                    widget.animIcon ?? Container(),
                    widget.icon ?? Container(),
                    widget.imageIcon ?? Container(),
                    widget.child ?? Container(), // icon
                  ],
                ),
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