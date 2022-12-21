import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/CardHeader.dart';

import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String header;
  const Header({Key? key, required this.header}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, left: 5.0),
      width: MediaQuery.of(context).size.width,
      child: Container(
        margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 15.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: const BorderRadius.all(Radius.circular(15.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
              color: Colors.transparent,
              child: const CardHeader(
                title: '',
                backArrow: true,
                noPadding: true,
              ),
            ),
            Expanded(
              child: AutoSizeText(header,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  minFontSize: 16.0,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontSize: 24.0,
                    color: Colors.white.withOpacity(0.85),
                  )),
            ),
            const SizedBox(
              width: 6,
            ),
          ],
        ),
      ),
    );
  }
}
