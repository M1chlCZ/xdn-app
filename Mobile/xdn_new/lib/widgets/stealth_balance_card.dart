import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/coin_badge.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StealthBalanceCard extends StatefulWidget {
  final double? balance;
  final VoidCallback send;
  final String address;

  const StealthBalanceCard({super.key, this.balance, required this.send, required this.address});

  @override
  State<StealthBalanceCard> createState() => _StealthBalanceCardState();
}

class _StealthBalanceCardState extends State<StealthBalanceCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        image: const DecorationImage(
          image: AssetImage("images/test_pattern.png"),
          fit: BoxFit.cover,
          opacity: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 4,
            blurRadius: 15,
            offset: const Offset(0, 5), // changes position of shadow
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 230,
                            child: AutoSizeText(NumberFormat('#,##0.#####').format((widget.balance ?? 0.0)),
                                textAlign: TextAlign.center, minFontSize: 12, maxLines: 1, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white)),
                          )),
                    ),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(alignment: Alignment.centerRight, child: CoinBadge(text: "XDN")),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 30),
              FlatCustomButton(
                  height: 40,
                  width: 100,
                  radius: 10,
                  onTap: () {
                    Dialogs.openUserQRToken(context, widget.address);
                    // getAddr();
                  },
                  color: Colors.transparent,
                  borderColor: Colors.white38,
                  borderWidth: 1.0,
                  child: AutoSizeText(AppLocalizations.of(context)!.receive,
                      maxLines: 1,
                      minFontSize: 8,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
              const Spacer(),
              FlatCustomButton(
                  height: 40,
                  width: 100,
                  radius: 10,
                  onTap: () {widget.send();},
                  color: Colors.transparent,
                  borderColor: Colors.white38,
                  borderWidth: 1.0,
                  child: AutoSizeText(AppLocalizations.of(context)!.send,
                      maxLines: 1,
                      minFontSize: 8,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
              const SizedBox(width: 30),
            ],
          ),
        ],
      ),
    );
  }

}
