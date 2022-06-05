import 'package:flutter/material.dart';

class SmallMenuTile extends StatelessWidget {
  final String name;
  final VoidCallback goto;

  const SmallMenuTile({Key? key, required this.name, required this.goto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: goto,
      child: Container(
          height: 90,
          margin: const EdgeInsets.only(left: 2.0, right: 2.0),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            gradient: LinearGradient(
              colors: [Color(0xFF828BDA), Color(0xFF8AB1F6)],
              begin: Alignment(-1.0, 4.0),
              end: Alignment(1.0, -4.0),
            ),
            image: DecorationImage(image: AssetImage("images/card.png"), fit: BoxFit.fitHeight),
          ),
          child: Center(
              child: Text(
            name,
            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0),
          ))),
    );
  }
}
