import 'package:flutter/material.dart';

import 'OvalButton.dart';

class CardHeader extends StatelessWidget {
  final String title;
  final bool backArrow;

  const CardHeader({Key? key, required this.title, this.backArrow = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
        padding: const EdgeInsets.only(left: 10.0),
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            backArrow == true
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0.0, top: 5.0),
                      child: OvalButton(
                        width: 60,
                        height: 60,
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          size: 30,
                          color: Colors.white,
                        ),
                        splashColor: Colors.deepPurpleAccent,
                        color: Colors.transparent,
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 24.0,
                ),
              ),
            )
          ],
        ));
  }
}
