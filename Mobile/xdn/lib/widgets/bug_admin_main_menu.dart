import 'package:flutter/material.dart';

class BugAdminMainMenu extends StatefulWidget {
  final VoidCallback goto;

  const BugAdminMainMenu({Key? key, required this.goto}) : super(key: key);

  @override
  State<BugAdminMainMenu> createState() => _BugAdminMainMenuState();
}

class _BugAdminMainMenuState extends State<BugAdminMainMenu> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: GestureDetector(
        onTap: () {
          widget.goto();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 3,
                offset: const Offset(0, 5), // changes position of shadow
              ),
            ],
            image: const DecorationImage(image: AssetImage("images/test_pattern.png"),fit: BoxFit.cover, opacity: 1.0),
          ),
          height: 45,
          child: Stack(
            children: [
              Center(
                child: Text(
                  "Bug Reports",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white54, fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0.0, top: 2.0, bottom: 5.0),
                child: Opacity(
                  opacity: 0.8,
                  child: SizedBox(width: 64, child: Image.asset("images/bug_big.png")),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
