import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../support/CardHeader.dart';
import '../support/NetInterface.dart';
import '../widgets/backgroundWidget.dart';
import '../widgets/balanceCard.dart';
import '../widgets/sendWidget.dart';
import '../widgets/transactionWidget.dart';

class DetailScreenWidget extends StatefulWidget {
  @override
  DetailScreenState createState() => DetailScreenState();
  final VoidCallback? refreshData;

  const DetailScreenWidget({Key? key, this.refreshData}) : super(key: key);
}

final Map<String, dynamic> payload = {};

class DetailScreenState extends State<DetailScreenWidget>
    with TickerProviderStateMixin {
  final GlobalKey<SendWidgetState> _key = GlobalKey();
  final GlobalKey<TransactionWidgetState> _keyTran = GlobalKey();
  final GlobalKey<BalanceCardState> _keyBal = GlobalKey();

  Future<Map<String, dynamic>>? _getBalance;

  AnimationController? animationController;
  AnimationController? animationSendController;
  Animation<double>? tween;
  Animation<Offset>? sendTween;
  Animation<double>? opacityTween;
  bool _forward = false;

  void refreshBalance() {
    setState(() {
      _getBalance = NetInterface.getBalance(details: true);
    });
  }

  void notif() {
    refreshBalance();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_keyTran.currentState != null) {
        _keyTran.currentState!.refreshTransaction();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    refreshBalance();
    animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    animationSendController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    sendTween = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 0.28)).animate(
        CurvedAnimation(parent: animationSendController!, curve: Curves.easeOut));

    opacityTween = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animationSendController!, curve: Curves.easeOut));

    tween = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: animationController!, curve: Curves.easeOut));
  }

  void shrinkSendView() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      animationController!.reverse();
      animationSendController!.reverse();
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
      animationController!.reverse();
      animationSendController!.reverse();
      _forward = false;
    } else {
      animationController!.forward();
      animationSendController!.forward();
      _key.currentState!.initView();
      _forward = true;
    }
  }

  void showTransactions() {
    animateButton();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    animationController!.dispose();
    animationSendController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        image: "walleticon.png",
        mainMenu: false,),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 15.0),
            decoration: const BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
            ),
            child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: FadeTransition(
                      opacity: opacityTween!,
                      child: SlideTransition(
                        position: sendTween!,
                        child: SendWidget(
                          key: _key,
                          func: shrinkSendView,
                          balance: _getBalance,
                        ),
                      ),
                    ),
                  ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: BalanceCard(
                      key: _keyBal,
                      getBalanceFuture: _getBalance,
                      onPressSend: showTransactions,
                    ),
                  ),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: _forward ? true : false,
                      child: FadeTransition(
                        opacity: tween!,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10.0),
                          child: TransactionWidget(
                            key: _keyTran,
                            func: refreshDataScroll,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              CardHeader(title: AppLocalizations.of(context)!.wl_balance, backArrow: true,),
            ]),
          ),
        ),
      ),
    ]);
  }
}
