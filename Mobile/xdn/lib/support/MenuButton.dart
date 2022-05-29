import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MenuButton extends StatefulWidget {
  final VoidCallback? open;
  const MenuButton({Key? key, this.open}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _MenuButton();
}

class _MenuButton extends State<MenuButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  final Tween<double> _tween = Tween(begin: 1, end: 1.05);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: <Widget>[
          Align(
            child: ScaleTransition(
              scale: _tween.animate(CurvedAnimation(
                  parent: _controller, curve: Curves.linear)),
              child: GestureDetector(
                onTap: () {
                  widget.open!();
                },
                child: Image.asset(
                  'images/menubutton.png',
                  // color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      );

  }
}
