import 'package:flutter/material.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/extensions.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';

class RestartOverlay extends ModalRoute<void> {
  int mnIndex = 0;
  VoidCallback? onTap;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  RestartOverlay(int mnI, VoidCallback onTapped) {
    onTap = onTapped;
    mnIndex = mnI;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.5,
            decoration: BoxDecoration(
              color: const Color(0xFF2C3353),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                gapH32,
                const Text(
                  'Restart your Masternode',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 24.0),
                ),
                gapH16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Go to your QT wallet to Masternode section and then click on ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12.0),
                    ),
                    Text(
                      'MN$mnIndex',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12.0),
                    ),
                    const Text(
                      ' and then press start',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12.0),
                    ),
                  ],
                ),
                gapH20,
                SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Image.asset("assets/images/tut_start.png")),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: FlatCustomButton(
                        height: 50,
                        width: MediaQuery.of(context).size.width * 0.3,
                        radius: 8,
                        splashColor: Colors.amber,
                        color: Colors.green,
                        onTap: () {
                          if (onTap != null) {
                            onTap!();
                          }
                          // showAlertDialog(context: context, title: "Shit", content: "bla bla bla bla bla bla");
                        },
                        child: Text(
                          "I started MN$mnIndex in my QT wallet".hardcoded,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          top: 20,
          child: FlatCustomButton(
            color: Colors.blueAccent,
            radius: 8,
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
