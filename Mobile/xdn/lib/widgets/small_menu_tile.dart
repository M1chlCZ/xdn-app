import 'package:auto_size_text/auto_size_text.dart';
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
          decoration:  BoxDecoration(
            borderRadius: const BorderRadius.all( Radius.circular(15.0)),
            gradient: const LinearGradient(
              colors: [ Color(0xFF3D3E4B),  Color(0xFF262C44),
                ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 3,
                blurRadius: 4,
                offset: const Offset(5, 3), // changes position of shadow
              ),
            ],
            image: const DecorationImage(image: const AssetImage("images/card.png"), fit: BoxFit.fitHeight),
          ),
          child: Center(
              child: AutoSizeText(
            name,
            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0),
                minFontSize: 8.0,
                maxLines: 1,
          ))),
    );
  }
}
