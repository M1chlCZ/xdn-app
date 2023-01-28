import 'dart:async';

import 'package:digitalnote/bloc/transaction_bloc.dart';
import 'package:digitalnote/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'TransactionView.dart';

class TransactionWidget extends ConsumerStatefulWidget {
  final VoidCallback? func;

  @override
  TransactionWidgetState createState() => TransactionWidgetState();

  const TransactionWidget({Key? key, this.func}) : super(key: key);
}

class TransactionWidgetState extends ConsumerState<TransactionWidget> {
  bool shouldRefresh = true;
  bool _circleVisible = true;
  TransactionBloc tb = TransactionBloc();
  RequestProvider? tx;

  @override
  void initState() {
    super.initState();
    _getShit();
  }

  Future<void> _getShit() async {
    // tb.fetchTransactions();

    Future.delayed(Duration.zero, () {
      tx = ref.watch(transactionProvider.notifier);
      tx?.getRequest();
    });
    //
  }

  // Future<void> refreshTransaction() async {
  //   await NetInterface.getTranData();
  //   tb.fetchTransactions();
  // }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.read(transactionProvider);
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
                onRefresh: () async {
                  await tx?.getRequest();
                },
                child: transactions.when(data: (data) {
                  Future.delayed(Duration.zero, () {
                    setState(() {
                      _circleVisible = false;
                    });
                  });
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return TransactionView(key: ValueKey<String>(data[index]!.txid!), customLocale: Localizations.localeOf(context).languageCode, transaction: data[index]);
                    },
                  );
                }, error: (Object error, StackTrace stackTrace) {
                  return Text(error.toString());
                }, loading: () {
                  Future.delayed(Duration.zero, () {
                    setState(() {
                      _circleVisible = true;
                    });
                  });
                  return const Center(child: CircularProgressIndicator());
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
