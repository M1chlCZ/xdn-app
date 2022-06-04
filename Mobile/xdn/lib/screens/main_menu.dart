import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/daemon_status.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/balanceCard.dart';
import 'package:digitalnote/widgets/balance_card.dart';
import 'package:digitalnote/widgets/small_menu_tile.dart';
import 'package:digitalnote/widgets/staking_menu_widget.dart';
import 'package:flutter/material.dart';

class MainMenuNew extends StatefulWidget {
  final String? locale;

  const MainMenuNew({Key? key, this.locale}) : super(key: key);

  @override
  State<MainMenuNew> createState() => _MainMenuNewState();
}

class _MainMenuNewState extends State<MainMenuNew> {
  ComInterface cm = ComInterface();
  final GlobalKey<BalanceCardState> _keyBal = GlobalKey();
  Future<Map<String, dynamic>>? _getBalance;

  void refreshBalance() {
    setState(() {
      _getBalance = NetInterface.getBalance(details: true);
    });
  }

  Future<DaemonStatus> _getDaemonStatus() async {
    Map<String, dynamic> m = {
      "request": "getDaemonStatus",
    };

    var req = await cm.get("/data", request: m);
    DaemonStatus dm = DaemonStatus.fromJson(req);
    return dm;
  }

  @override
  void initState() {
    super.initState();
    refreshBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          const BackgroundWidget(
            mainMenu: true,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 50,
                ),
                SizedBox(
                  width: 200.0,
                    child: Image.asset("images/logo.png")),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning',
                            style: Theme.of(context)
                                .textTheme
                                .headline5!
                                .copyWith(fontSize: 14.0),
                          ),
                          Text('Jakub Novak',
                              style: Theme.of(context).textTheme.headline5),
                        ],
                      ),
                      const AvatarPicker(
                        userID: null,
                        size: 100.0,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                BalanceCardMainMenu(
                    key: _keyBal, getBalanceFuture: _getBalance),
                const SizedBox(
                  height: 10,
                ),
                const StakingMenuWidget(),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: const [
                      Expanded(
                          child: SmallMenuTile(
                        name: "Messages",
                      )),
                      Expanded(child: SmallMenuTile(name: "Contacts")),
                      Expanded(child: SmallMenuTile(name: "Settings")),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: FutureBuilder<DaemonStatus>(
                          initialData: DaemonStatus(
                              block: false,
                              blockStake: false,
                              stakingActive: false),
                          future: _getDaemonStatus(),
                          builder: (ctx, snapshot) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.white10),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15.0,
                                        right: 15.0,
                                        top: 2.0,
                                        bottom: 2.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Daemon status",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(fontSize: 8.0),
                                        ),
                                        const SizedBox(
                                          width: 5.0,
                                        ),
                                        Icon(
                                          Icons.circle,
                                          size: 10.0,
                                          color: snapshot.data!.block!
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20.0,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.white10),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15.0,
                                        right: 15.0,
                                        top: 2.0,
                                        bottom: 2.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Staking daemon status",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(fontSize: 8.0),
                                        ),
                                        const SizedBox(
                                          width: 5.0,
                                        ),
                                        Icon(
                                          Icons.circle,
                                          size: 10.0,
                                          color: snapshot.data!.blockStake!
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.white10),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15.0,
                                        right: 15.0,
                                        top: 2.0,
                                        bottom: 2.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Staking active",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(fontSize: 8.0),
                                        ),
                                        const SizedBox(
                                          width: 5.0,
                                        ),
                                        Icon(
                                          Icons.circle,
                                          size: 10.0,
                                          color: snapshot.data!.stakingActive!
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
