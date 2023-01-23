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
      print(e);
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
      print(e);
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
                                              width: MediaQuery.of(context).size.width * 0.35,
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
                                          SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                                          Text(
                                            "${data[index].amount} XDN",
                                            textAlign: TextAlign.start,
                                            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70, fontWeight: FontWeight.w100, fontSize: 16),
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
                                  trailing: Row(
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
                                      )
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
                children: const [
                  Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                  SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
