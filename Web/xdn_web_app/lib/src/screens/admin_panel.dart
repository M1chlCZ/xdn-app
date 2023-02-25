import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/provider/request_provider.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/auth_repo.dart';
import 'package:xdn_web_app/src/support/s_p.dart';
import 'package:xdn_web_app/src/support/utils.dart';
import 'package:xdn_web_app/src/widgets/alert_dialogs.dart';
import 'package:xdn_web_app/src/widgets/background_widget.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';
import 'package:xdn_web_app/src/widgets/responsible_center.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final authRepository = ref.watch(authRepositoryProvider);
      final p = ref.read(requestProvider.notifier);
      p.getRequest();
      if (authRepository.currentUser?.admin == null) {
        context.pop();
      }
    });
  }

  void unsure(int id) async {
    final net = ref.read(networkProvider);
    final p = ref.read(requestProvider.notifier);
    try {
      showWaitDialog(context: context, title: "Please wait", content: "Unsure request");
      await net.post("/request/unsure", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      p.getRequest();
      if (mounted) context.pop();
      if (mounted) showExceptionAlertDialog(context: context, title: "Success", exception: "Allow: successful");
    } catch (e) {
      if (mounted) context.pop();
      showExceptionAlertDialog(context: context, title: "Error", exception: e.toString());
    }
  }

  void vote(int id, bool upvote) async {
    final net = ref.read(networkProvider);
    final p = ref.read(requestProvider.notifier);
    try {
      showWaitDialog(context: context, title: "Please wait", content: "Vote request");
      await net.post("/request/vote", body: {"id": id, "up": upvote}, serverType: ComInterface.serverGoAPI, debug: true);
      p.getRequest();
      if (mounted) context.pop();
      if (mounted) showExceptionAlertDialog(context: context, title: "Success", exception: "Allow: successful");
    } catch (e) {
      if (mounted) context.pop();
      showExceptionAlertDialog(context: context, title: "Error", exception: e.toString());
    }
  }

  void allow(int id) async {
    final net = ref.read(networkProvider);
    final p = ref.read(requestProvider.notifier);
    try {
      showWaitDialog(context: context, title: "Please wait", content: "Allow request");
      await net.post("/request/allow", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      p.getRequest();
      if (mounted) context.pop();
      if (mounted) showExceptionAlertDialog(context: context, title: "Success", exception: "Allow: successful");
    } catch (e) {
      if (mounted) context.pop();
      showExceptionAlertDialog(context: context, title: "Error", exception: e.toString());
    }
  }

  void deny(int id) async {
    final net = ref.read(networkProvider);
    final p = ref.read(requestProvider.notifier);
    try {
      showWaitDialog(context: context, title: "Please wait", content: "Allow request");
      await net.post("/request/deny", body: {"id": id}, serverType: ComInterface.serverGoAPI);
      p.getRequest();
      if (mounted) context.pop();
      if (mounted) showExceptionAlertDialog(context: context, title: "Success", exception: "Deny: successful");
    } catch (e) {
      if (mounted) context.pop();
      showExceptionAlertDialog(context: context, title: "Error", exception: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final reqProvider = ref.watch(requestProvider);
    return Stack(
      children: [
        const BackgroundWidget(
          mainMenu: false,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: ResponsiveCenter(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                  width: 200,
                  child: Image.asset(
                    "assets/images/logo.png",
                    color: Colors.white70,
                  )),
              gapH12,
              Text(
                "Admin console",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70, fontWeight: FontWeight.w100, fontSize: 12),
              ),
              gapH32,
              Card(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    width: MediaQuery.of(context).size.width * 1,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: reqProvider.when(
                      data: (data) {
                        return ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: ListTile(
                                  title: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                              width: 450,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(data[index].username ?? "null"),
                                                  const SizedBox(height: 5),
                                                  FlatCustomButton(
                                                    color: Colors.transparent,
                                                    splashColor: Colors.black12,
                                                    alignment: CrossAxisAlignment.start,
                                                    onTap: () {
                                                      Utils.openLink("https://xdn-explorer.com/address/${data[index].address}");
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          data[index].address ?? "null",
                                                          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14.0),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        const Icon(
                                                          Icons.open_in_browser,
                                                          size: 20,
                                                          color: Colors.white54,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )),
                                          Expanded(
                                            child: Text(
                                              "${data[index].amount} XDN",
                                              textAlign: TextAlign.start,
                                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70, fontWeight: FontWeight.w100, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(Utils.convertDate(data[index].datePosted),
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 12)),
                                      const SizedBox(height: 5),
                                    ],
                                  ),
                                  leading: const Icon(Icons.person, color: Colors.white70),
                                  textColor: Colors.white70,
                                  trailing: Stack(
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
                                ),
                              );
                            });
                      },
                      error: (error, stack) => Center(child: Text(error.toString())),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        Positioned(
          top: 85,
          left: 75,
          child: FlatCustomButton(
            radius: 8.0,
            color: Colors.black12,
            splashColor: Colors.amber,
            onTap: () {
              context.pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
