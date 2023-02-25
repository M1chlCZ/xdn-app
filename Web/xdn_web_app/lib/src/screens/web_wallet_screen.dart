import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/provider/transaction_provider.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/widgets/alert_dialogs.dart';
import 'package:xdn_web_app/src/widgets/background_widget.dart';
import 'package:xdn_web_app/src/widgets/balance_card.dart';
import 'package:xdn_web_app/src/widgets/button_bar.dart';
import 'package:xdn_web_app/src/widgets/transaction_view.dart';

class WebWalletScreen extends ConsumerStatefulWidget {
  const WebWalletScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WebWalletScreen> createState() => _WebWalletScreenState();
}

class _WebWalletScreenState extends ConsumerState<WebWalletScreen> {
  RequestProvider? tx;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      tx = ref.read(transactionProvider.notifier);
      tx?.getRequest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isBig = width > 600;
    final transactions = ref.watch(transactionProvider);
    return Stack(
      children: [
      const BackgroundWidget(mainMenu: false,),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                gapH128,
                const BalanceCard(),
                gapH12,
                ButtonBarWidget(onSend: sendCoins,),
                gapH12,
                Expanded(
                  child: SizedBox(
                    width: isBig ? 600 : width * 0.95,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await tx?.getRequest();
                      },
                      child: transactions.when(data: (data) {
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: data.length,
                          physics: const  BouncingScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            return TransactionView(key: ValueKey<String>(data[index]!.txid!), customLocale: Localizations.localeOf(context).languageCode, transaction: data[index]);
                          },
                        );
                      }, error: (Object error, StackTrace stackTrace) {
                        return Text(error.toString());
                      }, loading: () {
                        return const Center(child: CircularProgressIndicator());
                      }),
                    ),
                  ),
                ),
            ],),
          )
        ),
      ),
    ],);
  }

  void sendCoins(String address, double amount) {
    try {
      Navigator.of(context).pop();
      String method = "/user/send";
      Map<String, dynamic>? m;
      ComInterface interface = ComInterface();
      showWaitDialog(context: context, title: "Sending coins");
      if (address.isNotEmpty && amount != 0.0) {
        m = {
          "address": address,
          "amount": amount,
        };
      }else{
        throw Exception("Invalid address or amount");
      }

      if (!RegExp(r"^\b(d)[a-zA-Z0-9]{33}$").hasMatch(address)) {
        throw Exception("Invalid address");
      }

      Future.delayed(const Duration(milliseconds: 100), () async {
        await interface.post(method, body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
        if (mounted) {
          Navigator.of(context).pop();
          showAlertDialog(context: context, title: "Success", content: "Coins sent");
        }
      });
    } catch (e) {
      Navigator.of(context).pop();
      try {
        var err = e.toString().split("Exception: ")[1];
        showAlertDialog(context: context, title: "Error", content: err);
      } catch (err) {
        var er = json.decode(e.toString());
        showAlertDialog(context: context, title: "Error", content: er["errorMessage"]);
      }
    }
  }
}
