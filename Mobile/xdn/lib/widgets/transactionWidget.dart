import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/AppDatabase.dart';
import '../support/NetInterface.dart';
import '../support/TranSaction.dart';
import '../support/TransactionView.dart';

class TransactionWidget extends StatefulWidget {
  final VoidCallback? func;

  TransactionWidgetState createState() => TransactionWidgetState();

  TransactionWidget({Key? key, this.func}) : super(key: key);
}

class TransactionWidgetState extends State<TransactionWidget> {
  bool shouldRefresh = true;
  Future<List<TranSaction>>? _transactions;
  bool _circleVisible = true;

  @override
  void initState() {
    super.initState();
    _getShit();
  }

  void _getShit() async {
    _transactions = AppDatabase().getTransactions();
    var i = await NetInterface.getTranData();
    try {
      if (i > 0) {
        setState(() {
          _transactions = AppDatabase().getTransactions();
          _circleVisible = false;
        });
      }
    } catch (e) {
      print(e);
    }

    await AppDatabase().getLastTransactionDate();
  }

  Future<void> refreshTransaction() async {
    if (_circleVisible == true) return;
    setState(() {
      _circleVisible = true;
    });
    await NetInterface.getTranData();
    _transactions = AppDatabase().getTransactions();
    setState(() {
      _circleVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20, bottom: 10.0),
                child: Text(AppLocalizations.of(context)!.rec_tx, textAlign: TextAlign.start, style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 20.0)),
              ),
              Visibility(
                visible: _circleVisible,
                child: Padding(
                  padding: const EdgeInsets.only(right: 30.0, bottom: 5.0),
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.white70,
                    ),
                  ),
                ),
              )
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.58,
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 0.0, bottom: 0.0),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Container(

                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
                    child: FutureBuilder(
                        future: _transactions,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            var data = snapshot.data as List<TranSaction>;
                            return RefreshIndicator(
                              onRefresh: refreshTransaction,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: data.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return new TransactionView(customLocale: Localizations.localeOf(context).languageCode, transaction: data[index]);
                                },
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text(
                              snapshot.error.toString(),
                              style: GoogleFonts.montserrat(fontStyle: FontStyle.normal, fontSize: 32, color: Colors.red),
                            ));
                          } else {
                            return Container();
                          }
                        }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
