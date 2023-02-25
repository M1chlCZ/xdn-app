import 'package:flutter/material.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';
import 'package:xdn_web_app/src/widgets/send_widget.dart';

class SendOverlay extends ModalRoute<void> {
  final void Function(String address, double amount) onSend;

  SendOverlay({
    Key? key,
    required this.onSend,
  }) : super();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.6);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isBig = width > 600;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: isBig ? 600 : width * 0.8,
                  child: SendWidget(
                    send: onSend,
                  ),
                ),
    ),
            ],
          ),
        ),
      ),
    );
  }
}