import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class SmallMenuTile extends StatelessWidget {
  final String name;
  final VoidCallback goto;
  final String iconName;

  const SmallMenuTile({Key? key, required this.name, required this.iconName, required this.goto}) : super(key: key);

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
              colors: [Color(0xFF26345A),
                Color(0xFF2E4DA0)
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
            image: const DecorationImage(image: AssetImage("images/test_pattern.png"), fit: BoxFit.cover, opacity: 0.9),
          ),
          child: Stack(
            children: [
              Center(
                  child: AutoSizeText(
                name,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0),
                    minFontSize: 8.0,
                    maxLines: 1,
              )),
              Center(
                child: SizedBox(
                    width: 90,
                    child: Image.asset("images/${iconName.toLowerCase()}_big.png")),
              )
            ],
          )),
    );
  }
}
