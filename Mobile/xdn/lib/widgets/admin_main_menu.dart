import 'package:flutter/material.dart';

class AdminMainMenu extends StatefulWidget {
  final VoidCallback goto;

  const AdminMainMenu({Key? key, required this.goto}) : super(key: key);

  @override
  State<AdminMainMenu> createState() => _AdminMainMenuState();
}

class _AdminMainMenuState extends State<AdminMainMenu> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: GestureDetector(
        onTap: () {
          widget.goto();
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            boxShadow: [
            ],
            image: DecorationImage(image: AssetImage("images/test_pattern.png"),fit: BoxFit.cover, opacity: 1.0),
          ),
          height: 45,
          child: Stack(
            children: [
              Center(
                child: Text(
                  "Withrawal Requests",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white54, fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0.0, top: 2.0, bottom: 5.0),
                child: Opacity(
                  opacity: 0.8,
                  child: SizedBox(width: 64, child: Image.asset("images/wallet_big.png")),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
