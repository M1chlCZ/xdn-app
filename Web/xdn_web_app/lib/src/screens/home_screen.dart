import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xdn_web_app/src/models/MNList.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/overlay/restart_ovr.dart';
import 'package:xdn_web_app/src/overlay/start_ovr.dart';
import 'package:xdn_web_app/src/provider/mn_list_provider.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/s_p.dart';
import 'package:xdn_web_app/src/support/secure_storage.dart';
import 'package:xdn_web_app/src/support/utils.dart';
import 'package:xdn_web_app/src/widgets/alert_dialogs.dart';
import 'package:xdn_web_app/src/widgets/background_widget.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';
import 'package:xdn_web_app/src/widgets/responsible_center.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(),
        Scaffold(
            backgroundColor: Colors.transparent,
            body: ResponsiveCenter(
                child: Stack(
              children: [
                Positioned(
                    right: 5,
                    top: 85,
                    child: FlatCustomButton(
                        radius: 8.0,
                        color: Colors.black12,
                        splashColor: Colors.black87,
                        onTap: () async {
                          await SecureStorage.deleteAllStorage();
                          if (mounted) context.pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(Icons.logout_sharp, color: Colors.white70),
                        ))),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 200,
                        child: Image.asset(
                          "assets/images/logo.png",
                          color: Colors.white70,
                        )),
                    gapH12,
                    Text(
                      "Non-Custodial Masternode Hosting",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70, fontWeight: FontWeight.w100, fontSize: 12),
                    ),
                    gapH32,
                    Card(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(Sizes.p20, Sizes.p20, Sizes.p24, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Text("ID"),
                                      gapW32,
                                      Text("IP"),
                                      gapW128,
                                      gapW32,
                                      gapW8,
                                      Text("Address"),
                                    ],
                                  ),
                                  Row(
                                    children: const [
                                      Text("Active Time"),
                                      gapW128,
                                      Text("Last Seen"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              indent: 10,
                              endIndent: 10,
                              color: Colors.white24,
                            ),
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final items = ref.watch(itemsProvider);
                                  if (items.hasError) {
                                    return Center(child: Text('Error: ${items.error}'));
                                  }
                                  if (items.isRefreshing || items.isLoading) {
                                    return const Center(child: SizedBox(width: Sizes.p32, height: Sizes.p32, child: CircularProgressIndicator()));
                                  }
                                  return Container(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                    width: MediaQuery.of(context).size.width * 1,
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: items.value!.length,
                                      itemBuilder: (context, index) {
                                        if (items.value![index] is MNList) {
                                          var data = items.value![index] as MNList;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: InkWell(
                                              customBorder: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              hoverColor: Colors.black26,
                                              splashColor: Colors.white24,
                                              onTap: () {
                                                _showOverlay(context, data.id ?? 0, () {
                                                  _restartNode(data.id ?? 0);
                                                });
                                              },
                                              child: Opacity(
                                                opacity: data.active == 0 ? 0.5 : 1,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: data.error == 0 ? Colors.black12 : Colors.red.withOpacity(0.5),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.only(top: Sizes.p16, bottom: Sizes.p16, left: Sizes.p8, right: Sizes.p8),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(data.id.toString()),
                                                          gapW24,
                                                          Text(data.ip ?? "ip"),
                                                          gapW24,
                                                          Text(data.addr ?? "addr"),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(Utils.formatDuration(Duration(seconds: data.activeTime!)).toString() ?? "port"),
                                                          gapW48,
                                                          gapW12,
                                                          Text(Utils.convertDate(data.lastSeen.toString())),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return InkWell(
                                              customBorder: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              hoverColor: Colors.lime.withOpacity(0.9),
                                              splashColor: Colors.white24,
                                              onTap: () {
                                                _showTutOverlay(context);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.lime.withOpacity(0.6),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.only(top: Sizes.p16, bottom: Sizes.p16, left: Sizes.p8, right: Sizes.p8),
                                                child: Center(
                                                    child: Text(
                                                  "START NEW XDN MN",
                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800),
                                                )),
                                              ));
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ))),
      ],
    );
  }

  void _restartNode(int id) {
    final network = ref.read(networkProvider);
    Future.delayed(Duration.zero, () async {
      try {
        await network.post("/masternode/non/restart", body: {"idNode": id}, serverType: ComInterface.serverGoAPI);
        if (mounted) showAlertDialog(context: context, title: "Success", content: "Node $id restarted");
      } catch (e) {
        var err = json.decode(e.toString());
        showAlertDialog(context: context, title: "Fail", content: err['errorMessage']);
      }
    });
    Navigator.of(context).pop();
    Future.delayed(const Duration(seconds: 1), () {
    }).then((value) => ref.refresh(itemsProvider));
  }

  void _showOverlay(BuildContext context, int mnId, VoidCallback onTap) {
    Navigator.of(context).push(RestartOverlay(mnId, onTap));
  }

  void _showTutOverlay(BuildContext context) {
    Navigator.of(context).push(StartOverlay()).then((value) => ref.refresh(itemsProvider));
  }
}
