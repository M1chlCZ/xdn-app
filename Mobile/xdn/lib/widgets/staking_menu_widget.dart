import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StakingMenuWidget extends StatefulWidget {
  final VoidCallback goto;
  const StakingMenuWidget({Key? key, required this.goto}) : super(key: key);

  @override
  State<StakingMenuWidget> createState() => _StakingMenuWidgetState();
}

class _StakingMenuWidgetState extends State<StakingMenuWidget> {
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
              spreadRadius: 3,
              blurRadius: 4,
              offset: const Offset(0, 5), // changes position of shadow
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
                        AppLocalizations.of(context)!.st_headline,
                        style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white70, fontSize: 26, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                )),
            Padding(
              padding: const EdgeInsets.only(left:2.0, top: 4.0),
              child: SizedBox(
                  width: 85,
                  child: Image.asset("images/staking_big.png")),
            )
          ],
        ),
      ),
    );
  }
}
