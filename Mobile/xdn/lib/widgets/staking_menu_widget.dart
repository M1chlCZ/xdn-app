import 'package:flutter/material.dart';

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
        height: 100,
        margin: const EdgeInsets.only(left: 10.0, right: 10.0),
        decoration:  BoxDecoration(
          borderRadius: BorderRadius.all(const Radius.circular(15.0)),
          gradient: const LinearGradient(
            colors: [Color(0xFF313C5D),
              Color(0xFF4A5EB0)
              ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 4,
              offset: const Offset(0, 5), // changes position of shadow
            ),
          ],
          image: DecorationImage(image: AssetImage("images/card.png"), fit: BoxFit.fitWidth),
        ),
        child: Stack(
          children: [
            Center(
                child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Staking',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(
                    width: 70.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: SizedBox(
                        width: 100.0,
                        height: 100.0,
                        child: Image.asset(
                          "images/graph.png",
                        )),
                  ),
                ],
              ),
            )),
            Padding(
              padding: const EdgeInsets.only(left:8.0, top: 8.0),
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
