import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/addrScreen.dart';
import 'package:digitalnote/screens/messagescreen.dart';
import 'package:digitalnote/screens/stakingScreen.dart';
import 'package:digitalnote/screens/walletscreen.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/daemon_status.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/balanceCard.dart';
import 'package:digitalnote/widgets/balance_card.dart';
import 'package:digitalnote/widgets/small_menu_tile.dart';
import 'package:digitalnote/widgets/staking_menu_widget.dart';
import 'package:flutter/material.dart';
import '../globals.dart' as globals;

class MainMenuNew extends StatefulWidget {
  static const String route = "/menu";
  final String? locale;

  const MainMenuNew({Key? key, this.locale}) : super(key: key);

  @override
  State<MainMenuNew> createState() => _MainMenuNewState();
}

class _MainMenuNewState extends State<MainMenuNew> {
  final GlobalKey<BalanceCardState> _keyBal = GlobalKey();
  final GlobalKey<DetailScreenState> _walletKey = GlobalKey();
  ComInterface cm = ComInterface();

  Future<Map<String, dynamic>>? _getBalance;

  String? name;

  @override
  void initState() {
    super.initState();
    refreshBalance();
    getInfo();
  }

  getInfo() async {
    name = await SecureStorage.read(key: globals.NICKNAME);
    setState(() {});
  }

  void refreshBalance() {
    setState(() {
      _getBalance = NetInterface.getBalance(details: true);
    });
  }

  void gotoBalanceScreen() async {
    // Navigator.of(context).push(CupertinoPageRoute(
    //     builder: (context) => DetailScreenWidget(
    //       key: _walletKey,
    //     )));
    Navigator.of(context).pushNamed(WalletScreen.route, arguments: "shit");
  }

  void gotoContactScreen() async {
    Navigator.of(context).pushNamed(AddressScreen.route);
  }

  void gotoStakingScreen() async {
    Navigator.of(context).pushNamed(StakingScreen.route, arguments: "shit");
  }

  void gotoMessagesScreen() async {
    Navigator.of(context).pushNamed(MessageScreen.route, arguments: "shit");
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 0.0),
                      child: SizedBox(
                          width: 200.0,
                          child: Image.asset("images/logo.png", color: Colors.white70,)),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
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
                            style: Theme
                                .of(context)
                                .textTheme
                                .headline5!
                                .copyWith(fontSize: 14.0),
                          ),
                          Text(name ?? '',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .headline5),
                        ],
                      ),
                      const AvatarPicker(
                        userID: null,
                        size: 100.0,
                        color: Colors.transparent,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                BalanceCardMainMenu(
                  key: _keyBal, getBalanceFuture: _getBalance, goto: gotoBalanceScreen,),
                const SizedBox(
                  height: 10,
                ),
                StakingMenuWidget(goto: gotoStakingScreen,),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(child: SmallMenuTile(name: "Messages", goto: gotoMessagesScreen)),
                      Expanded(child: SmallMenuTile(name: "Contacts", goto: gotoContactScreen,)),
                      Expanded(child: SmallMenuTile(name: "Settings", goto: gotoContactScreen)),
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
                                        left: 10.0,
                                        right: 10.0,
                                        top: 2.0,
                                        bottom: 2.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Wallet daemon status",
                                          style: Theme
                                              .of(context)
                                              .textTheme
                                              .headline5!
                                              .copyWith(fontSize: 8.0, letterSpacing: 0.5),
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
                                  width: 10.0,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.white10),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10.0,
                                        right: 10.0,
                                        top: 2.0,
                                        bottom: 2.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Staking daemon status",
                                          style: Theme
                                              .of(context)
                                              .textTheme
                                              .headline5!
                                              .copyWith(fontSize: 8.0, letterSpacing: 0.5),
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
                                          style: Theme
                                              .of(context)
                                              .textTheme
                                              .headline5!
                                              .copyWith(fontSize: 8.0, letterSpacing: 0.5),
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
