import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:konjungate/support/BackgroundArc.dart';

class BackgroundWidget extends StatefulWidget {
  final bool mainMenu;
  final bool hasImage;
  final String? image;
  final bool arc;

  const BackgroundWidget({Key? key, this.mainMenu = false, this.hasImage = true, this.image, this.arc = false}) : super(key: key);

  @override
  _BackgroundWidgetState createState() => _BackgroundWidgetState();
}

class _BackgroundWidgetState extends State<BackgroundWidget> {

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return widget.mainMenu
        ? Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              widget.arc ? 'images/settingsbg.png' : 'images/mainmenubg.png',
              fit: BoxFit.fitWidth,
            ),
          )
        : Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'images/sectionbackground.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
              widget.arc ? BackgroundArc(width: height, height: width) : Container(),
             SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Expanded(child: Container()),
                    widget.hasImage ? Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: 70,
                        child: Image.asset(
                          'images/' + widget.image!,
                          color: Colors.white.withAlpha(50),
                          alignment: Alignment.bottomCenter,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ) : Container(),
                  ],
                ),
              ),

            ],
          );
  }
}
