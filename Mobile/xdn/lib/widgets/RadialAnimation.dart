import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konjungate/support/AppDatabase.dart';
import 'package:vector_math/vector_math.dart' show radians;

import '../support/MenuButton.dart';

class RadialAnimation extends StatefulWidget {
  RadialAnimation({Key? key, required this.controller, this.callback, required this.admPriv, required this.ambPriv})
      : translation = Tween<double>(
          begin: 0.0,
          end: 120.0,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ),
        scale = Tween<double>(
          begin: 1.5,
          end: 0.0,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn),
        ),
        rotation = Tween<double>(
          begin: 0.0,
          end: 360.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(
              0.0,
              0.7,
              curve: Curves.decelerate,
            ),
          ),
        ),
        super(key: key);

  final AnimationController controller;
  final Animation<double> rotation;
  final Animation<double> translation;
  final Animation<double> scale;
  final Function(String name)? callback;
  final bool? ambPriv;
  final bool? admPriv;

  @override
  _RadialAnimationState createState() => _RadialAnimationState();
}

class _RadialAnimationState extends State<RadialAnimation> {
  var forward = true;
  int unread = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      _button();
    });
  }

  void getUnread() async {
    var r = (await AppDatabase().getUnread())!;
    setState(() {
      unread = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 800), () {
      getUnread();
    });
    return AnimatedBuilder(
        animation: widget.controller,
        builder: (context, widget) {
          return Transform.rotate(
              angle: radians(this.widget.rotation.value),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Stack(alignment: Alignment.center, children: <Widget>[
                  _buildButton(
                    90,
                    color: Colors.green,
                    text: AppLocalizations.of(context)!.messages,
                    svg: false,
                    badge: true,
                    image: "images/messageicon.png",
                    callBack: this.widget.callback,
                  ),
                  _buildButton(
                    0,
                    color: Colors.orange,
                    text: AppLocalizations.of(context)!.contacts,
                    svg: false,
                    image: "images/contactsicon.png",
                    callBack: this.widget.callback,
                  ),
                  _buildButton(
                    270,
                    color: Colors.pink,
                    text: AppLocalizations.of(context)!.menu_wallet,
                    svg: false,
                    image: "images/walleticon.png",
                    callBack: this.widget.callback,
                  ),
                  _buildButton(
                    180,
                    color: Colors.yellow,
                    text: AppLocalizations.of(context)!.st_headline,
                    svg: false,
                    image: "images/stakingicon.png",
                    callBack: this.widget.callback,
                  ),
                  SizedBox(
                      width: 100.0,
                      height: 100.0,
                      child: MenuButton(
                        open: _close,
                      )),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.31,
                      height: MediaQuery.of(context).size.width * 0.31,
                      child: MenuButton(
                        open: _button,
                      )),
                ]),
              ));
        });
  }

  _button() {
    if (forward) {
      _open();
      forward = false;
    } else {
      _close();
      forward = true;
    }
  }

  _open() {
    widget.controller.forward();
  }

  _close() {
    widget.controller.reverse();
  }

  _buildButton(double angle, {Color? color, IconData? icon, String? text, Function(String name)? callBack, String? image, bool? svg, bool? justImage, bool badge = false}) {
    final double rad = radians(angle);
    return Transform(
      transform: Matrix4.identity()..translate((widget.translation.value) * cos(rad), (widget.translation.value) * sin(rad)),
      child: SizedBox(
        width: 100,
        height: 100,
        child: justImage == true
            ? GestureDetector(
                onTap: () {
                  callBack!(text!);
                },
                child: Image.asset(
                  image!,
                  // color: Colors.black87,
                ))
            : badge
                ? Badge(
                    position: BadgePosition.topEnd(top: 7, end: 12),
                    animationDuration: const Duration(milliseconds: 300),
                    animationType: BadgeAnimationType.slide,
                    badgeColor: const Color(0xFF4a4578),
                    padding: const EdgeInsets.all(10.0),
                    showBadge: unread == 0 ? false : true,
                    badgeContent: Text(
                      unread.toString(),
                      style: Theme.of(context).textTheme.headline6!.copyWith(color:Colors.white, fontWeight: FontWeight.w300, fontSize: 14.0),
                    ),
                    child: RawMaterialButton(
                      fillColor: Colors.transparent,
                      shape: const CircleBorder(side: BorderSide(color: Colors.transparent, width: 2.0)),
                      elevation: 0.0,
                      child: image == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  color: Colors.black87,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                SizedBox(
                                  width: 80,
                                  child: AutoSizeText(
                                    text!,
                                    maxLines: 1,
                                    minFontSize: 8.0,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.normal, fontStyle: FontStyle.normal, color: Colors.black87, fontSize: 18.0),
                                  ),
                                )
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: svg == true
                                        ? SvgPicture.asset(image)
                                        : Image.asset(
                                            image,
                                            fit: BoxFit.fitWidth,
                                            isAntiAlias: true,
                                          )),
                                SizedBox(
                                    width: 80,
                                    child: AutoSizeText(
                                      text!,
                                      maxLines: 1,
                                      minFontSize: 8.0,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.normal, color: Colors.white, fontSize: 14.0),
                                    )),
                              ],
                            ),
                      onPressed: () {
                        callBack!(text);
                      },
                    ),
                  )
                : RawMaterialButton(
                    fillColor: Colors.transparent,
                    shape: const CircleBorder(side: BorderSide(color: Colors.transparent, width: 2.0)),
                    elevation: 0.0,
                    child: image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                color: Colors.black87,
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              SizedBox(
                                width: 80,
                                child: AutoSizeText(
                                  text!,
                                  maxLines: 1,
                                  minFontSize: 8.0,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.normal, fontStyle: FontStyle.normal, color: Colors.black87, fontSize: 18.0),
                                ),
                              )
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: svg == true
                                      ? SvgPicture.asset(image)
                                      : Image.asset(
                                          image,
                                          fit: BoxFit.fitWidth,
                                          isAntiAlias: true,
                                        )),
                              SizedBox(
                                  width: 88,
                                  child: AutoSizeText(
                                    text!,
                                    maxLines: 1,
                                    minFontSize: 8.0,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.normal, color: Colors.white, fontSize: 14.0),
                                  )),
                            ],
                          ),
                    onPressed: () {
                      callBack!(text);
                    },
                  ),
      ),
    );
  }
}
