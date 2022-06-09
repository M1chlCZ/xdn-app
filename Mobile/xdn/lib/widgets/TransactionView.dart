import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../support/Dialogs.dart';
import '../support/TranSaction.dart';

class TransactionView extends StatelessWidget {
  final TranSaction? transaction;
  final String? customLocale;

  String _getMeDate(String? d) {
    if (d == null) return "";
    var date = DateTime.parse(d);
    var format = DateFormat.yMd(Platform.localeName).add_jm();
    return format.format(date);
  }

  const TransactionView({Key? key, this.transaction, this.customLocale}) : super(key: key);

  Widget _checkContactName(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 2.0, left: 0.0),
      child: Center(
        child: SizedBox(
          width: 150,
          child: AutoSizeText(
            _getText(transaction!.contactName, context),
            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 18.0, color: Colors.white70),
            minFontSize: 14,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _getText(String? s, BuildContext context) {
    if (s == null || s == "null") {
      return transaction!.category == 'send' ? AppLocalizations.of(context)!.sent : AppLocalizations.of(context)!.deposit;
    } else {
      return s == 'Staking' ? AppLocalizations.of(context)!.st_headline : s;
    }
  }

  Widget _getTxIcon(BuildContext context) {
    if (transaction!.confirmation! < 2) {
      return const Icon(
        Icons.hourglass_bottom_outlined,
        size: 50,
        color: Colors.white30,
      );
    } else if (transaction!.category == 'send') {
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
    return Opacity(
      opacity: transaction!.confirmation! < 2 ? 0.5 : 1.0,
      child: Card(
          elevation: 0,
          color: Colors.transparent,
          margin: const EdgeInsets.only(bottom: 2.0),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: InkWell(
            splashColor: Colors.black54,
            highlightColor: Colors.black54,
            onTap: () {
              Dialogs.openTransactionBox(context, transaction!);
            },
            child: Container(
              alignment: Alignment.centerLeft,
              width: 280.0,
              height: 64.0,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF423D70), Color(0xFF5D57A6)],
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
                              _getMeDate(transaction!.datetime),
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
                          transaction!.category == "receive" ? "+ ${transaction!.amount!} XDN" : "- ${transaction!.amount!.replaceFirst('-', '')} XDN",
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w300, fontSize: 16, color: transaction!.category! == "receive" ? Colors.white70 : Colors.white30),
                          minFontSize: 8,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
