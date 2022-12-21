import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/models/TokenTx.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';


class TokenTxView extends StatelessWidget {
  final Tx? transaction;
  final String address;
  final String? customLocale;

  String _getMeDate(int? d) {
    if (d == null) return "";
    var t = d * 1000;
    var date = DateTime.fromMillisecondsSinceEpoch(t);
    var format = DateFormat.yMd(Platform.localeName).add_jm();
    return format.format(date);
  }

  const TokenTxView({Key? key, this.transaction, this.customLocale, required this.address}) : super(key: key);

  Widget _checkContactName(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 2.0, left: 0.0),
      child: Center(
        child: SizedBox(
          width: 150,
          child: AutoSizeText(
            _getText(transaction!.fromAddr, context),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18.0, color: Colors.white70),
            minFontSize: 14,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _getText(String? s, BuildContext context) {
      return address == transaction!.fromAddr ? AppLocalizations.of(context)!.sent : AppLocalizations.of(context)!.deposit;

  }

  Widget _getTxIcon(BuildContext context) {
    if (address == transaction!.fromAddr ) {
      return const Icon(
        Icons.keyboard_arrow_up,
        size: 50,
        color: Colors.white30,
      );
    } else {
      return const Icon(
        Icons.keyboard_arrow_down,
        size: 50,
        color: Colors.white30,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();
    return Card(
        elevation: 3,
        color: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 8.0, left: 10, right: 10),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: InkWell(
          splashColor: Colors.black54,
          highlightColor: Colors.black54,
          onTap: () {
            // Dialogs.openTransactionBox(context, transaction!);
          },
          child: Container(
            alignment: Alignment.centerLeft,
            width: 280.0,
            height: 64.0,
            decoration: const BoxDecoration(

              gradient: LinearGradient(
                colors: [Color(0xFF222D52),
                  Color(0xFF384F91)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: Flex(
              direction: Axis.horizontal,
              children: [
                Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(5.0, 5.0, 6.0, 5.0),
                      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10.0)), color: Colors.white10),
                      child: Center(child: _getTxIcon(context)),
                    )),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                      _checkContactName(context),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0.0, top: 5.0),
                        child: SizedBox(
                          width: 120,
                          child: AutoSizeText(
                            _getMeDate(transaction!.timestampTX!.toInt()).toString(),
                            // style: Theme.of(context).textTheme.headline51!.copyWith(color: Colors.white70),
                            style: GoogleFonts.montserrat(fontSize: 11.0, fontWeight: FontWeight.w300, color: Colors.white54),
                            textAlign: TextAlign.start,
                            minFontSize: 8,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 125,
                      child: AutoSizeText(
                        address == transaction!.toAddr ? "+ ${_transactionAmount(transaction!.amount!)} WXDN" : "- ${_transactionAmount(transaction!.amount!)} WXDN",
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w300, fontSize: 16, color: address == transaction!.toAddr? Colors.white70 : Colors.white30),
                        minFontSize: 8,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  String _transactionAmount(String amnt) {
    var big = BigInt.parse(amnt);
    var amount = big / BigInt.from(10).pow(transaction!.contractDecimal!.toInt());
    return Utils.formatBalance(amount.toDouble());
  }
}
