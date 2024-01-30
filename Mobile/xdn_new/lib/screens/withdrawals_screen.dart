import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/models/Withdrawals.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/card_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WithdrawalsScreen extends StatefulWidget {
  static const String route = "home/withdrawals";

  const WithdrawalsScreen({super.key});

  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  var finished = false;

  Future<List<Requests>?> getRequests() async {
    try {
      // setState(() {
      //   finished = false;
      // });
      var response = await ComInterface().get("/request/list", serverType: ComInterface.serverGoAPI, debug: true);
      Withdrawals res = Withdrawals.fromJson(response);

      // setState(() {
      //   finished = true;
      // });
      return res.requests;
      // if (res != null) {
      //   List<Requests> requests = [];
      //   for (var item in response['requests']) {
      //     requests.add(Requests.fromJson(item));
      //   }
      //   return requests;
      // } else {
      //   return [];
      // }
    } catch (e) {
      setState(() {
        finished = true;
      });
      print(e);
      return [];
    }
  }

  String _getMeDate(String d) {
    final format = DateFormat.yMEd(Platform.localeName).add_Hm();

    var dateTime = DateTime.now();
    var dateObject = DateTime.parse(d);
    var offset = dateTime.timeZoneOffset * -1;
    DateTime? date;
    if (!offset.isNegative) {
      date = dateObject.add(Duration(hours: offset.inHours));
    } else {
      date = dateObject.subtract(Duration(hours: offset.inHours));
    }
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          const BackgroundWidget(),
          SafeArea(
              child: Column(children: [
            const Header(header: "Withdrawals"),
            const SizedBox(
              height: 5.0,
            ),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: FutureBuilder<List<Requests>?>(
                      future: getRequests(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 2.0,
                          ));
                        }
                        if (snapshot.hasData) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    color: snapshot.data![index].processed == 0 ? Colors.yellow : snapshot.data![index].send == 1 ? Colors.lime : Colors.redAccent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                snapshot.data![index].processed != null
                                                    ? snapshot.data![index].processed == 1
                                                        ? "Processed"
                                                        : "Pending"
                                                    : "Pending",
                                                style: const TextStyle(color: Colors.black87, fontSize: 12.0),
                                              ),
                                              const SizedBox(
                                                width: 10.0,
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment: Alignment.centerRight,
                                                  child: AutoSizeText(
                                                    "${Utils.formatBalance(snapshot.data![index].amount!).toString()} XDN",
                                                    maxLines: 1,
                                                    minFontSize: 10,
                                                    style: const TextStyle(color: Colors.black87, fontSize: 12.0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10.0,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Submitted:",
                                                style: TextStyle(color: Colors.black87, fontSize: 12.0),
                                              ),
                                              Text(
                                                _getMeDate(snapshot.data![index].datePosted.toString()),
                                                style: const TextStyle(color: Colors.black87, fontSize: 12.0),
                                              ),
                                            ],
                                          ),
                                          if (snapshot.data![index].processed != 0)
                                            Column(
                                              children: [
                                                const Divider(
                                                  color: Colors.white12,
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      snapshot.data![index].auth == 1 ? "SENT" : "Deny",
                                                      maxLines: 1,
                                                      textAlign: TextAlign.end,
                                                      style: const TextStyle(color:Colors.black54, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    Icon(snapshot.data![index].send == 1 ? Icons.check_circle_outline : Icons.watch_later_outlined, color: Colors.black54)
                                                  ],
                                                ),

                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      })),
            ),
          ])),
        ],
      ),
    );
  }
}
