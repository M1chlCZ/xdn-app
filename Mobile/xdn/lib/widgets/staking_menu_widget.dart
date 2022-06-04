import 'package:flutter/material.dart';

class StakingMenuWidget extends StatefulWidget {
  const StakingMenuWidget({Key? key}) : super(key: key);

  @override
  State<StakingMenuWidget> createState() => _StakingMenuWidgetState();
}

class _StakingMenuWidgetState extends State<StakingMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(left: 10.0, right: 10.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
        gradient: LinearGradient(
          colors: [Color(0xFFB2B6FC),
            Color(0xFF86A0EA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: DecorationImage(
            image: AssetImage("images/card.png"), fit: BoxFit.fitWidth),
      ),
      child: Center(
          child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              'Staking',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(width: 70.0,),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: SizedBox(
                width: 100.0,
                  height: 100.0,
                  child: Image.asset("images/graph.png",)),
            ),
          ],
        ),
      )),
    );
  }
}
