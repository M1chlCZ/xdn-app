import 'dart:async';

import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/NetInterface.dart';
import '../widgets/backgroundWidget.dart';
import '../widgets/balanceCard.dart';
import '../widgets/sendWidget.dart';
import '../widgets/transactionWidget.dart';

class WalletScreen extends ConsumerStatefulWidget {
  static const String route = "menu/wallet";

  @override
  DetailScreenState createState() => DetailScreenState();
  final VoidCallback? refreshData;

  const WalletScreen({super.key, this.refreshData});
}

final Map<String, dynamic> payload = {};

class DetailScreenState extends ConsumerState<WalletScreen> with TickerProviderStateMixin {
  final GlobalKey<SendWidgetState> _key = GlobalKey();
  final GlobalKey<TransactionWidgetState> _keyTran = GlobalKey();
  final GlobalKey<BalanceCardState> _keyBal = GlobalKey();

  Map<String, dynamic>? _priceData;

  bool _forward = false;
  Widget? _switchWidget;
  double? heightVal;
  bool? useTablet;

  void refreshBalance() {
  }

  getPriceData() async {
    _priceData = await NetInterface.getPriceData();
    setState(() {});
  }

  void notif() {
    refreshBalance();
    // Future.delayed(const Duration(milliseconds: 200), () {
    //   if (_keyTran.currentState != null) {
    //     _keyTran.currentState!.refreshTransaction();
    //   }
    // });
  }

  @override
  void initState() {
    super.initState();
    refreshBalance();
    _switchWidget = balanceCard();
  }

  void shrinkSendView() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      _forward = false;
      setState(() {
        refreshBalance();
      });
    });
  }

  void refreshDataScroll() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${AppLocalizations.of(context)!.wl_refreshing}..."),
      duration: const Duration(seconds: 1),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.fixed,
      elevation: 5.0,
    ));
    setState(() {
      refreshBalance();
    });
  }

  void animateButton() {
    if (_forward) {
      setState(() {
        _switchWidget = balanceCard();
        _forward = false;
      });
    } else {
      setState(() {
        _switchWidget = sendWidget();
        _forward = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        _key.currentState!.initView();
      });
    }
  }

  void showTransactions() {
    animateButton();
  }


  @override
  Widget build(BuildContext context) {
    heightVal = MediaQuery.of(context).size.height * 0.3;
    useTablet = Utils.isTablet(MediaQuery.of(context));
    return Stack(children: [
      const BackgroundWidget(
        image: "walleticon.png",
        mainMenu: false,
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(children: [
            Column(
              children: [
                Header(header: AppLocalizations.of(context)!.wl_balance),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.bounceIn,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _switchWidget,
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10.0),
                    child: TransactionWidget(
                      key: _keyTran,
                      func: refreshDataScroll,
                    ),
                  ),
                ),
              ],
            ),
            // CardHeader(title: AppLocalizations.of(context)!.wl_balance, backArrow: true,),
          ]),
        ),
      ),
    ]);
  }

  Widget balanceCard() {
    return Padding(
      key: const ValueKey<int>(0),
      padding: const EdgeInsets.only(top: 0.0),
      child: BalanceCard(
        key: _keyBal,
        onPressSend: showTransactions,
      ),
    );
  }

  Widget sendWidget() {
    return Padding(
      key: const ValueKey<int>(1),
      padding: const EdgeInsets.only(top: 0.0),
      child: SendWidget(
        key: _key,
        func: shrinkSendView,
        cancel: showTransactions,
      ),
    );
  }
}
