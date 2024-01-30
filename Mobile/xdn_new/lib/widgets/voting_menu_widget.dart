import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VotingMenuWidget extends StatefulWidget {
  final VoidCallback goto;
  final bool isVoting;
  const VotingMenuWidget({super.key, required this.goto, this.isVoting = false});

  @override
  State<VotingMenuWidget> createState() => _VotingMenuWidgetState();
}

class _VotingMenuWidgetState extends State<VotingMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.goto,
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(left: 10.0, right: 10.0),
        decoration:  BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(15.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(2, 4), // changes position of shadow
            ),
          ],
          image: const DecorationImage(image: AssetImage("images/test_pattern.png"), fit: BoxFit.cover, opacity: 1.0),
        ),
        child: Stack(
          children: [
            Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 58.0, right: 50.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.voting,
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white70, fontSize: 26, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                )),
            Padding(
              padding: const EdgeInsets.only(left:4.0, top: 2.0, bottom: 4.0),
              child: SizedBox(
                  width: 85,
                  child: Image.asset("images/voting_big.png")),
            ),
            Visibility(
              visible: widget.isVoting,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: AvatarGlow(
                      glowColor: Colors.white,
                      duration: const Duration(milliseconds: 1500),
                      repeat: true,
                      animate: true,
                      curve: Curves.easeOut,
                      child: Container(
                        height: 5.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      )),
                ),),
            )
          ],
        ),
      ),
    );
  }
}
