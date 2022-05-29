import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'RadialAnimation.dart';

class RadialMenu extends StatefulWidget {
  final Function(String name)? callback;
  final bool? ambPriv;
  final bool? admPriv;

  RadialMenu({Key? key, this.callback, this.admPriv, this.ambPriv});

  createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    // ..addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return RadialAnimation(controller: controller,callback: widget.callback, admPriv: widget.admPriv, ambPriv: widget.ambPriv,);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
