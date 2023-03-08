import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/providers/req_provider.dart';
import 'package:digitalnote/providers/wallet_balance_provider.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/widgets/backgroundWidget.dart';
import 'package:digitalnote/widgets/button_flat.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminScreen extends ConsumerStatefulWidget {
  static const String route = "home/admin";

  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final p = ref.read(requestProvider.notifier);
      p.getRequest();
    });
  }

  void unsure(int id) async {
    final net = ComInterface();
    final p = ref.read(requestProvider.notifier);
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/unsure", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      p.getRequest();
      if (mounted) Navigator.of(context).pop();
      if (mounted) Dialogs.openAlertBox(context, "Success", "Allow: successful");
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      Dialogs.openAlertBox(context, "Error", e.toString());
      print(e);
    }
  }

  void vote(int id, bool upvote) async {
    final net = ComInterface();
    final p = ref.read(requestProvider.notifier);
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/vote", body: {"id": id, "up": upvote}, serverType: ComInterface.serverGoAPI, debug: true);
      p.getRequest();
      if (mounted) Navigator.of(context).pop();
      if (mounted) Dialogs.openAlertBox(context, "Success", "Vote: successful");
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      Dialogs.openAlertBox(context, "Error", e.toString());
      print(e);
    }
  }

  void allow(int id) async {
    final net = ComInterface();
    final p = ref.read(requestProvider.notifier);
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/allow", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      p.getRequest();
      if (mounted) Navigator.of(context).pop();
      if (mounted) Dialogs.openAlertBox(context, "Success", "Allow: successful");
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      Dialogs.openAlertBox(context, "Error", e.toString());
      print(e);
    }
  }

  void deny(int id) async {
    final net = ComInterface();
    final p = ref.read(requestProvider.notifier);
    try {
      Dialogs.openWaitBox(context);
      await net.post("/request/deny", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      p.getRequest();
      if (mounted) Navigator.of(context).pop();
      if (mounted) Dialogs.openAlertBox(context, "Success", "Deny: successful");
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      Dialogs.openAlertBox(context, "Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final reqProvider = ref.watch(requestProvider);
    final bal = ref.watch(allBalanceProvider);
    return Stack(
      children: [
        const BackgroundWidget(
          mainMenu: false,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              const Header(header: "Withdraw Requests"),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: bal.when(
                    data: (data) {
                      return Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AutoSizeText(
                          "Wallet: ${NumberFormat("#,###.##", "en_US").format(double.parse(data['wallet'].toString()))} XDN",
                          style: const TextStyle(fontSize: 16.0),
                          maxLines: 1,
                          minFontSize: 8.0,
                        ),
                        AutoSizeText(
                          "Stale wallet: ${NumberFormat("#,###.##", "en_US").format(double.parse(data['stakeWallet'].toString()))} XDN",
                          style: const TextStyle(fontSize: 16.0),
                          maxLines: 1,
                          minFontSize: 8.0,
                        ),
                      ]));
                    },
                    error: (err, st) {
                      var error = json.decode(err.toString());
                      return Center(child: Text(error['errorMessage'], style: const TextStyle(fontSize: 14.0)));
                    },
                    loading: () => const Center(child: Text("Loading wallet data..."))),
              ),
              SizedBox(height: 15.0,),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: reqProvider.when(
                    data: (data) {
                      return ListView.builder(
                          itemCount: data.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                              color: Colors.black12,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person, color: Colors.white70),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                                child: Text(data[index].username ?? "null"),
                                              ),
                                              const SizedBox(width: 5),
                                            ],
                                          ),
                                        ),
                                        Stack(
                                          children: [
                                            if (data[index].currentUser == false && data[index].idUserVoting != 0)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    hoverColor: Colors.limeAccent.withOpacity(0.5),
                                                    icon: const Icon(
                                                      Icons.thumb_up_alt_sharp,
                                                      color: Colors.lime,
                                                    ),
                                                    onPressed: () {
                                                      vote(data[index].id!, true);
                                                    },
                                                  ),
                                                  const SizedBox(width: 10),
                                                  IconButton(
                                                    hoverColor: Colors.redAccent.withOpacity(0.5),
                                                    icon: const Icon(
                                                      Icons.thumb_down_alt_sharp,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      vote(data[index].id!, false);
                                                    },
                                                  )
                                                ],
                                              ),
                                            if (data[index].currentUser == true && data[index].idUserVoting != 0)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    hoverColor: Colors.redAccent.withOpacity(0.5),
                                                    icon: const Icon(
                                                      Icons.block,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      deny(data[index].id!);
                                                    },
                                                  ),
                                                  const SizedBox(width: 10),
                                                  IconButton(
                                                    hoverColor: Colors.lime.withOpacity(0.5),
                                                    icon: const Icon(
                                                      Icons.check,
                                                      color: Colors.lime,
                                                    ),
                                                    onPressed: () {
                                                      allow(data[index].id!);
                                                    },
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        data[index].downvotes.toString(),
                                                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      const Icon(
                                                        Icons.thumb_down_alt_sharp,
                                                        color: Colors.red,
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        data[index].upvotes.toString(),
                                                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.lime, fontWeight: FontWeight.w900, fontSize: 12),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      const Icon(
                                                        Icons.thumb_up_alt_sharp,
                                                        color: Colors.lime,
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            if (data[index].currentUser == false && data[index].idUserVoting == 0)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    hoverColor: Colors.redAccent.withOpacity(0.5),
                                                    icon: const Icon(
                                                      Icons.block,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      deny(data[index].id!);
                                                    },
                                                  ),
                                                  const SizedBox(width: 10),
                                                  IconButton(
                                                    hoverColor: Colors.lime.withOpacity(0.5),
                                                    icon: const Icon(
                                                      Icons.check,
                                                      color: Colors.lime,
                                                    ),
                                                    onPressed: () {
                                                      allow(data[index].id!);
                                                    },
                                                  ),
                                                  const SizedBox(width: 10),
                                                  IconButton(
                                                    hoverColor: Colors.amber.withOpacity(0.5),
                                                    icon: const Icon(
                                                      Icons.thumbs_up_down,
                                                      color: Colors.amber,
                                                    ),
                                                    onPressed: () {
                                                      unsure(data[index].id!);
                                                    },
                                                  )
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 0),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(Utils.convertDate(data[index].datePosted),
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70, fontWeight: FontWeight.w100, fontSize: 12)),
                                  ),
                                  const SizedBox(height: 5),
                                  Center(
                                    child: Text(
                                      "${data[index].amount} XDN",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70, fontWeight: FontWeight.w400, fontSize: 16),
                                    ),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: FlatCustomButton(
                                        color: Colors.black12,
                                        splashColor: Colors.black12,
                                        alignment: CrossAxisAlignment.center,
                                        onTap: () {
                                          Utils.openLink("https://xdn-explorer.com/address/${data[index].address}");
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                data[index].address ?? "null",
                                                style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10.0, color: Colors.white70, fontWeight: FontWeight.w300),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                Icons.open_in_new,
                                                size: 14,
                                                color: Colors.white54,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),
                            );
                          });
                    },
                    error: (error, stack) {
                      var e = json.decode(error.toString());
                      return Center(
                          child: Container(
                              width: 300,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black12, width: 1),
                              ),
                              child: Center(
                                  child: Text(
                                e['errorMessage'],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ))));
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
