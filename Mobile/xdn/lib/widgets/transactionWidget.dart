import 'dart:async';

import 'package:digitalnote/bloc/transaction_bloc.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/NetInterface.dart';
import '../models/TranSaction.dart';
import 'TransactionView.dart';

class TransactionWidget extends StatefulWidget {
  final VoidCallback? func;

  @override
  TransactionWidgetState createState() => TransactionWidgetState();

  const TransactionWidget({Key? key, this.func}) : super(key: key);
}

class TransactionWidgetState extends State<TransactionWidget> {
  bool shouldRefresh = true;
  bool _circleVisible = true;
  TransactionBloc tb = TransactionBloc();

  @override
  void initState() {
    super.initState();
    _getShit();
  }

  Future<void> _getShit() async {
    tb.fetchTransactions();
    // _transactions = AppDatabase().getTransactions();
    // var i = await NetInterface.getTranData();
    // try {
    //   if (i > 0) {
    //     setState(() {
    //       _transactions = AppDatabase().getTransactions();
    //       _circleVisible = false;
    //     });
    //   }
    // } catch (e) {
    //   if (kDebugMode) {
    //     print(e);
    //   }
    // }
    //
    // await AppDatabase().getLastTransactionDate();
  }

  Future<void> refreshTransaction() async {
    await NetInterface.getTranData();
    tb.fetchTransactions();
    // if (_circleVisible == true) return;
    // setState(() {
    //   _circleVisible = true;
    // });
    //
    // _transactions = AppDatabase().getTransactions();
    // setState(() {
    //   _circleVisible = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10.0),
              child: Text(AppLocalizations.of(context)!.rec_tx, textAlign: TextAlign.start, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 20.0)),
            ),
            Visibility(
              visible: _circleVisible,
              child: const Padding(
                padding: EdgeInsets.only(right: 30.0, bottom: 5.0),
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
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 10.0, right: 10.0, top: 0.0, bottom: 0.0),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 0), // changes position of shadow
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: RefreshIndicator(
                onRefresh: _getShit,
                child: StreamBuilder<ApiResponse<List<TranSaction>>>(
                    stream: tb.coinsListStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        switch (snapshot.data!.status) {
                          case Status.completed:
                            Future.delayed(Duration.zero, () {
                              setState(() {
                                _circleVisible = false;
                              });
                            });
                            var data = snapshot.data!.data;
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: data!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return TransactionView(
                                  key: ValueKey<String>(data[index].txid!),
                                    customLocale: Localizations.localeOf(context).languageCode, transaction: data[index]);
                              },
                            );
                          case Status.error:
                            Future.delayed(Duration.zero, () {
                              setState(() {
                                _circleVisible = false;
                              });
                            });
                            return Center(
                                child: Text(
                              snapshot.error.toString(),
                              style: GoogleFonts.montserrat(fontStyle: FontStyle.normal, fontSize: 32, color: Colors.red),
                            ));
                          case Status.loading:
                            Future.delayed(Duration.zero, () {
                              setState(() {
                                _circleVisible = true;
                              });
                            });
                            return Container();
                        }
                      } else {
                        return Container();
                      }
                    }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
