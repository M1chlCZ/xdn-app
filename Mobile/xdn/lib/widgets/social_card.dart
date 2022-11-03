import 'package:digitalnote/widgets/button_flat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SocialMediaCard extends StatefulWidget {
  final bool socials;
  final String? name;
  final String pictureName;
  final VoidCallback onTap;
  final Color cardActiveColor;
  final Function() unlink;

  const SocialMediaCard(
      {Key? key,
      required this.socials,
      this.name,
      required this.pictureName,
      required this.onTap,
      required this.cardActiveColor, required this.unlink})
      : super(key: key);

  @override
  SocialMediaCardState createState() => SocialMediaCardState();
}

class SocialMediaCardState extends State<SocialMediaCard>with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;
  bool _extended = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation =  Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animationController!, curve: Curves.fastLinearToSlowEaseIn));
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 20.0),
      child: Column(
        children: [
          SizedBox(
            height: 50.0,
            child: Card(
                elevation: 0,
                color: widget.socials == false
                    ? Colors.black12
                    : widget.cardActiveColor,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: InkWell(
                  splashColor: widget.cardActiveColor,
                  highlightColor: Colors.black54,
                  onTap: () {
                    if(kDebugMode) {
                      widget.socials != false ? print("yep") : print("nope");
                    }
                    if (widget.socials != false) {
                      if(_extended) {
                        _extended = false;
                        _animationController!.reverse();
                      }else{
                        _extended = true;
                        _animationController!.forward();
                      }
                    } else {
                      widget.onTap();
                    }

                  },
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 15.0,
                        ),
                        SizedBox(
                            width: 35.0,
                            child: Image.asset(
                              widget.pictureName,
                              color: Colors.white,
                            )),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, bottom: 0.0),
                          child: Text(
                            widget.name ?? "XDN TIP Bot",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4!
                                  .copyWith(fontSize: 18.0, color: Colors.white)),
                        ),
                        const Expanded(
                          child: SizedBox(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: IgnorePointer(
                            child: widget.socials == false
                                ? FlatCustomButton(
                                    height: 28,
                                    width: 32,
                                    color: Colors.transparent,
                                    child: RotatedBox(
                                      quarterTurns: 0,
                                      child: Icon(
                                        widget.socials != false
                                            ? Icons.check
                                            : Icons.arrow_forward_ios_sharp,
                                        color: Colors.white,
                                        size: 22.0,
                                      ),
                                    ))
                                : Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Icon(
                                      widget.socials != false
                                          ? Icons.check
                                          : Icons.arrow_forward_ios_sharp,
                                      color: Colors.white,
                                      size: 25.0,
                                    ),
                                  ),
                          ),
                        )
                      ],
                    ),
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: SizeTransition(
              sizeFactor: _animation!,
              child: Column(
                children: [
                  const SizedBox(height: 2.0,),
                  SizedBox(
                    height: 40.0,
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      color: widget.cardActiveColor,
                      child: InkWell(
                        splashColor: widget.cardActiveColor,
                        highlightColor: Colors.black54,
                        onTap: () async {
                          widget.unlink();
                         // await Dialogs.openSocDisconnectBox(context, 2, widget.name,
                         //          (soc) =>  widget.unlink(widget.socials!.socialMedia!));
                         //  _animationController!.reverse();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.unlink.replaceAll("{1}", ""), style: Theme.of(context)
                                .textTheme
                                .headline4!
                                .copyWith(fontSize: 18.0, color: Colors.white)),
                            const SizedBox(width: 0.0,),
                            const Icon(Icons.link_off, color: Colors.redAccent,),
                          ],
                        ),
                      ),

                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
