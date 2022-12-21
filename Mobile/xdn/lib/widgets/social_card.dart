import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/auto_size_text_field.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SocialMediaCard extends StatefulWidget {
  final bool socials;
  final String? name;
  final String pictureName;
  final VoidCallback onTap;
  final Color cardActiveColor;
  final Function(int typeBot) unlink;
  final String tokenCommand;
  final Function() showSnackBar;
  final String linkSocials;
  final int typeBot;

  const SocialMediaCard(
      {Key? key,
      required this.socials,
      this.name,
      required this.pictureName,
      required this.onTap,
      required this.cardActiveColor,
      required this.unlink,
      required this.tokenCommand,
      required this.showSnackBar,
      required this.linkSocials, required this.typeBot})
      : super(key: key);

  @override
  SocialMediaCardState createState() => SocialMediaCardState();
}

class SocialMediaCardState extends State<SocialMediaCard> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  AnimationController? _animationController;
  Animation<double>? _animation;
  bool _extended = false;
  bool _socials = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController!, curve: Curves.fastLinearToSlowEaseIn));
  }

  @override
  Widget build(BuildContext context) {
    _textController.text = widget.tokenCommand;
    _socials = widget.socials;
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 20.0),
      child: Column(
        children: [
          SizedBox(
            height: 50.0,
            child: Card(
                elevation: 0,
                color: _socials == false ? Colors.black12 : widget.cardActiveColor,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: InkWell(
                  splashColor: widget.cardActiveColor,
                  highlightColor: Colors.black54,
                  onTap: () {
                    if (kDebugMode) {
                      _socials != false ? print("yep") : print("nope");
                    }
                    if (_extended) {
                      _extended = false;
                      _animationController!.reverse();
                    } else {
                      _extended = true;
                      _animationController!.forward();
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
                          child: Text(widget.name!, style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 18.0, color: Colors.white)),
                        ),
                        const Expanded(
                          child: SizedBox(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: IgnorePointer(
                            child: _socials == false
                                ? FlatCustomButton(
                                    height: 28,
                                    width: 32,
                                    color: Colors.transparent,
                                    child: RotatedBox(
                                      quarterTurns: 0,
                                      child: Icon(
                                        _socials != false ? Icons.check : Icons.arrow_forward_ios_sharp,
                                        color: Colors.white,
                                        size: 22.0,
                                      ),
                                    ))
                                : Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Icon(
                                      _socials != false ? Icons.check : Icons.arrow_forward_ios_sharp,
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
              child: _socials
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 2.0,
                        ),
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
                                widget.unlink(widget.typeBot);
                                // await Dialogs.openSocDisconnectBox(context, 2, widget.name,
                                //          (soc) =>  widget.unlink(_socials!.socialMedia!));
                                //  _animationController!.reverse();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(AppLocalizations.of(context)!.unlink(""), style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 18.0, color: Colors.white)),
                                  const SizedBox(
                                    width: 0.0,
                                  ),
                                  const Icon(
                                    Icons.link_off,
                                    color: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(left: 0.0, right: 0.0),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        color: Color(0xFF7289DA),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  _launchURL(widget.linkSocials);
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      '- ${AppLocalizations.of(context)!.join_discord}',
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0),
                                    ),
                                    const SizedBox(
                                      width: 5.0,
                                    ),
                                    const Icon(
                                      Icons.open_in_new,
                                      color: Colors.white,
                                      size: 14.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 12.0,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Row(
                                children: [
                                  Text(
                                    '- ${AppLocalizations.of(context)!.send_discord}',
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Container(
                              // margin: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                              width: double.infinity,
                              height: 30.0,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                                color: Color(0xFF252525),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.82,
                                      child: AutoSizeTextField(
                                        maxLines: 1,
                                        minFontSize: 8.0,
                                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white, fontSize: 14.0),
                                        autocorrect: false,
                                        readOnly: true,
                                        controller: _textController,
                                        textAlign: TextAlign.left,
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.only(left: 4.0, right: 4.0),
                                          isDense: true,
                                          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white54, fontSize: 14.0),
                                          hintText: '',
                                          enabledBorder: const UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.transparent),
                                          ),
                                          focusedBorder: const UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.transparent),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 0.0, right: 3.0),
                                      child: SizedBox(
                                        width: 30.0,
                                        height: 25.0,
                                        child: FlatCustomButton(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: widget.tokenCommand));
                                              widget.showSnackBar();
                                            },
                                            color: const Color(0xFF7289DA),
                                            splashColor: Colors.black38,
                                            child: const Icon(
                                              Icons.content_copy,
                                              size: 18.0,
                                              color: Colors.white,
                                            )),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    var kUrl = url.replaceAll(" ", "+");
    Utils.openLink(kUrl);
  }
}
