
import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/addrScreen.dart';
import 'package:digitalnote/screens/message_screen.dart';
import 'package:digitalnote/screens/settingsScreen.dart';
import 'package:digitalnote/screens/stakingScreen.dart';
import 'package:digitalnote/screens/voting_screen.dart';
import 'package:digitalnote/screens/walletscreen.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/LifecycleWatcherState.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/daemon_status.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/models/summary.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/balanceCard.dart';
import 'package:digitalnote/widgets/balance_card.dart';
import 'package:digitalnote/widgets/small_menu_tile.dart';
import 'package:digitalnote/widgets/staking_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

import '../globals.dart' as globals;


class MainMenuNew extends StatefulWidget {
  static const String route = "menu";
  final String? locale;

  const MainMenuNew({Key? key, this.locale}) : super(key: key);

  @override
  State<MainMenuNew> createState() => _MainMenuNewState();
}

class _MainMenuNewState extends LifecycleWatcherState<MainMenuNew> {
  final GlobalKey<BalanceCardState> _keyBal = GlobalKey();
  ComInterface cm = ComInterface();

  Future<Map<String, dynamic>>? _getBalance;

  String? name;

  Sumry? sumry;

  Map<String, dynamic>? _priceData;

  SessionStatus? session;

  @override
  void initState() {
    _getLocale();
    super.initState();
    refreshBalance();
    getInfo();
    getPriceData();
    loginDao();
  }

  void loginDao() async {
   bool res = await NetInterface.daoLogin();
   if (res) {
      debugPrint('Dao login success');
    } else {
     debugPrint('Dao login failed');
   }
  }

  void getPriceData() async {
    _priceData = await NetInterface.getPriceData();
    setState(() {});
  }

  getInfo() async {
    name = await SecureStorage.read(key: globals.NICKNAME);
    await NetInterface.getAddrBook();
    sumry = await NetInterface.getSummary();
    setState(() {});
  }

  void _getLocale() async {
    var timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    await SecureStorage.write(key: globals.LOCALE, value: timeZoneName);
  }

  void refreshBalance() {
    setState(() {
      _getBalance = NetInterface.getBalance(details: true);
    });
  }

  void gotoBalanceScreen() {
    Navigator.of(context).pushNamed(WalletScreen.route, arguments: _getBalance).then((value) => refreshBalance());
  }

  void gotoContactScreen() {
    Navigator.of(context).pushNamed(AddressScreen.route);
  }

  void gotoStakingScreen() {
    Navigator.of(context).pushNamed(StakingScreen.route, arguments: "shit").then((value) => refreshBalance());
  }

  void gotoVotingScreen() {
    Navigator.of(context).pushNamed(VotingScreen.route, arguments: "shit").then((value) => refreshBalance());
  }

  void gotoMessagesScreen() {
    Navigator.of(context).pushNamed(MessageScreen.route, arguments: "shit");
  }

  void gotoSettingsScreen() {
    Navigator.of(context).pushNamed(SettingsScreen.route, arguments: "shit");
    // Dialogs.openAlertBox(context, "header", "\nNot yet implemented\n");
  }

  Future<DaemonStatus> getDaemonStatus() async {
    try {
      Map<String, dynamic> m = {
        "request": "getDaemonStatus",
      };

      var req = await cm.get("/data", request: m);
      DaemonStatus dm = DaemonStatus.fromJson(req);
      return dm;
    } catch (e) {
      return DaemonStatus(block: false, blockStake: false, stakingActive: false);
    }
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
                      child: GestureDetector(
                        onTap: () {
                          // loginUsingMetamask(context);
                          gotoVotingScreen();
                          // _createConnection();
                        },
                        child: SizedBox(
                            width: 200.0,
                            height: 50.0,
                            child: Image.asset(
                              "images/logo.png",
                              color: Colors.white70,
                            )),
                      ),
                    ),
                  ),
                ),
                Align(
                    alignment: Alignment.center,
                    child: Text(
                      "\$${_priceData?['usd'].toString() ?? "0.0"}",
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(color: Colors.white54),
                    )),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              _getDatetimeHeadline(),
                              style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 14.0),
                            ),
                            Text(name ?? '', style: Theme.of(context).textTheme.headline5),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(8.0)), color: Colors.black.withOpacity(0.2)),
                        child: const AvatarPicker(
                          userID: null,
                          size: 100.0,
                          color: Colors.transparent,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                BalanceCardMainMenu(
                  key: _keyBal,
                  getBalanceFuture: _getBalance,
                  goto: gotoBalanceScreen,
                ),
                const SizedBox(
                  height: 10,
                ),
                StakingMenuWidget(
                  goto: gotoStakingScreen,
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(child: SmallMenuTile(name: AppLocalizations.of(context)!.messages, iconName: "messages", goto: gotoMessagesScreen)),
                      Expanded(
                          child: SmallMenuTile(
                        name: AppLocalizations.of(context)!.contacts,
                        goto: gotoContactScreen,
                        iconName: "contacts",
                      )),
                      Expanded(
                          child: SmallMenuTile(
                        name: AppLocalizations.of(context)!.set_headline.capitalize(),
                        goto: gotoSettingsScreen,
                        iconName: "settings",
                      )),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: FutureBuilder<DaemonStatus>(
                          initialData: DaemonStatus(block: false, blockStake: false, stakingActive: false),
                          future: getDaemonStatus(),
                          builder: (ctx, snapshot) {
                            return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white10),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 2.0, bottom: 2.0),
                                      child: Row(
                                        children: [
                                          AutoSizeText(
                                            "Wallet daemon status",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                            minFontSize: 2.0,
                                          ),
                                          const SizedBox(
                                            width: 5.0,
                                          ),
                                          Icon(
                                            Icons.circle,
                                            size: 10.0,
                                            color: snapshot.data!.block! ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white10),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 2.0, bottom: 2.0),
                                      child: Row(
                                        children: [
                                          AutoSizeText(
                                            "Staking daemon status",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                            minFontSize: 2.0,
                                          ),
                                          const SizedBox(
                                            width: 5.0,
                                          ),
                                          Icon(
                                            Icons.circle,
                                            size: 10.0,
                                            color: snapshot.data!.blockStake! ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white10),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 2.0, bottom: 2.0),
                                      child: Row(
                                        children: [
                                          AutoSizeText(
                                            "Staking active",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                            minFontSize: 2.0,
                                          ),
                                          const SizedBox(
                                            width: 5.0,
                                          ),
                                          Icon(
                                            Icons.circle,
                                            size: 10.0,
                                            color: snapshot.data!.stakingActive! ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.97,
                                    padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 5.0, bottom: 5.0),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.black12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AutoSizeText(
                                          "Blockcount: ${sumry?.data?[0].blockcount ?? ''}",
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                          minFontSize: 2.0,
                                        ),
                                        const SizedBox(
                                          width: 5.0,
                                        ),
                                        AutoSizeText(
                                          "| Masternode count: ${sumry?.data?[0].masternodecount ?? ''}",
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                          minFontSize: 2.0,
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ]);
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

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {
    refreshBalance();
    getInfo();
  }

  String _getDatetimeHeadline() {
    DateTime d = DateTime.now();
    var hour = d.hour;
    if (hour > 0 && hour < 6) {
      return 'Good Night';
    } else if (hour > 6 && hour < 12) {
      return 'Good Morning';
    } else if (hour > 12 && hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
