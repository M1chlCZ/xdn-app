import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/models/MNList.dart';
import 'package:xdn_web_app/src/overlay/restart_ovr.dart';
import 'package:xdn_web_app/src/provider/mn_list_provider.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/utils.dart';
import 'package:xdn_web_app/src/widgets/background_widget.dart';
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
                child: Column(
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
                      Consumer(
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
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: InkWell(
                                      customBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      hoverColor: Colors.black26,
                                      splashColor: Colors.white24,
                                      onTap: () {
                                        _showOverlay(context, items.value![index].id ?? 0, () {
                                          _restartNode(items.value![index].id ?? 0);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.only(top: Sizes.p16, bottom: Sizes.p16, left: Sizes.p8, right: Sizes.p8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(items.value?[index].id.toString() ?? "id"),
                                                gapW24,
                                                Text(items.value?[index].ip ?? "ip"),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(Utils.formatDuration(Duration(seconds: items.value![index].activeTime!)).toString() ?? "port"),
                                                gapW48,
                                                gapW12,
                                                Text(Utils.convertDate(items.value?[index].lastSeen.toString()) ?? "status"),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }else{
                                  return InkWell(
                                    customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hoverColor: Colors.lime.withOpacity(0.8),
                                    splashColor: Colors.white24,
                                    onTap: () {
                                      _showOverlay(context, items.value![index].id ?? 0, () {
                                        _restartNode(items.value![index].id ?? 0);
                                      });
                                    },
                                    child: Container(
                                    decoration: BoxDecoration(
                                    color: Colors.lime.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                padding: const EdgeInsets.only(top: Sizes.p16, bottom: Sizes.p16, left: Sizes.p8, right: Sizes.p8),
                                child: Center(child: Text("START NEW XDN MN", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800),)),));
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ))),
      ],
    );
  }

  void _restartNode(int id) {
    Navigator.of(context).pop();
    print("restart node $id");
  }

  void _showOverlay(BuildContext context, int mnId, VoidCallback onTap) {
    Navigator.of(context).push(RestartOverlay(mnId, onTap));
  }
}
