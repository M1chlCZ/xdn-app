import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/models/summary.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/addrScreen.dart';
import 'package:digitalnote/screens/message_detail_screen.dart';
import 'package:digitalnote/screens/message_screen.dart';
import 'package:digitalnote/screens/settingsScreen.dart';
import 'package:digitalnote/screens/stakingScreen.dart';
import 'package:digitalnote/screens/token_screen.dart';
import 'package:digitalnote/screens/voting_screen.dart';
import 'package:digitalnote/screens/walletscreen.dart';
import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/LifecycleWatcherState.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/daemon_status.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/balanceCard.dart';
import 'package:digitalnote/widgets/balance_card.dart';
import 'package:digitalnote/widgets/balance_token_card.dart';
import 'package:digitalnote/widgets/small_menu_tile.dart';
import 'package:digitalnote/widgets/staking_menu_widget.dart';
import 'package:digitalnote/widgets/voting_menu_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:get_it/get_it.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

import '../globals.dart' as globals;
import '../models/MessageGroup.dart';

class MainMenuNew extends StatefulWidget {
  static const String route = "menu";
  final String? locale;

  const MainMenuNew({Key? key, this.locale}) : super(key: key);

  @override
  State<MainMenuNew> createState() => _MainMenuNewState();
}

class _MainMenuNewState extends LifecycleWatcherState<MainMenuNew> {
  final GlobalKey<BalanceCardState> _keyBal = GlobalKey();
  final GlobalKey<BalanceCardState> _keyTokenBal = GlobalKey();
  ComInterface cm = ComInterface();

  FutureOr<Map<String, dynamic>>? _getBalance;

  Future<Map<String, dynamic>>? _getTokenBalance;

  String? name;

  Map<String, dynamic>? _priceData;

  SessionStatus? session;

  bool contestActive = false;

  Future<DaemonStatus>? daemonStatus;

  AppDatabase db = GetIt.I.get<AppDatabase>();

  @override
  void initState() {
    _getLocale();
    super.initState();
    loginDao();
    getNotification();
  }

  void loginDao() async {
    refreshBalance();
    getInfo();
    getPriceData();
    String? s = await SecureStorage.read(key: globals.TOKEN_DAO);
    if (s != null) {
      bool contest = await NetInterface.checkContest();
      if (contest) {
        debugPrint('Contest is active');
        setState(() {
          contestActive = true;
        });
      } else {
        debugPrint('Contest is not active');
        setState(() {
          contestActive = false;
        });
      }
    } else {
      debugPrint('Dao not logged in');
    }
  }

  getNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      if (message.data['func'] == "sendMessage") {
        String sentAddr = message.data['fr'];
        String? contact = await db.getContactNameByAddr(sentAddr);
        MessageGroup m = MessageGroup(sentAddr: contact ?? sentAddr, sentAddressOrignal: sentAddr);
        if(mounted) Navigator.pushNamed(context, MessageDetailScreen.route, arguments: m);
      }
    });
  }

  getPriceData() async {
    _priceData = await NetInterface.getPriceData();
    setState(() {});
  }

  getInfo() async {
    name = await SecureStorage.read(key: globals.NICKNAME);
    setState(() {});
    daemonStatus = getDaemonStatus();
    // var token = await SecureStorage.read(key: globals.TOKEN);
    // print(token);
    NetInterface.getAddrBook();
  }

  void _getLocale() async {
    var timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    await SecureStorage.write(key: globals.LOCALE, value: timeZoneName);
  }

  refreshBalance() {
    _getBalance = NetInterface.getBalance(details: true);
    _getTokenBalance = NetInterface.getTokenBalance();
    setState(() {});
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

  void gotoTokenScreen() {
    Navigator.of(context).pushNamed(TokenScreen.route, arguments: "nothing");
  }

  void gotoSettingsScreen() {
    Navigator.of(context).pushNamed(SettingsScreen.route, arguments: "shit");
    // Dialogs.openAlertBox(context, "header", "\nNot yet implemented\n");
  }

  Future<DaemonStatus> getDaemonStatus() async {
    try {
      Map<String, dynamic> req = await cm.get("/status", serverType: ComInterface.serverGoAPI, debug:true);
      DaemonStatus dm = DaemonStatus.fromJson(req['data']);
      return dm;
    } catch (e) {
      debugPrint(e.toString());
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
            child: Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          child: Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 0.0),
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
                                decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(8.0)), color: Colors.black.withOpacity(0.1)),
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
                        BalanceTokenCardMenu(
                          key: _keyTokenBal,
                          getBalanceFuture: _getTokenBalance,
                          goto: gotoTokenScreen,
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
                        VotingMenuWidget(
                          goto: gotoVotingScreen,
                          isVoting: contestActive,
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
                        const SizedBox(
                          height: 100,
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: FutureBuilder<DaemonStatus>(
                        initialData: DaemonStatus(block: false, blockStake: false, stakingActive: false, blockCount: 0, masternodeCount: 0),
                        future: daemonStatus,
                        builder: (ctx, snapshot) {
                          return Container(
                            height: 65,
                            margin: const EdgeInsets.only(left: 4.0, right: 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF333A57),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF333A57),
                                  Color(0xFF2C334E)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10.0,
                                  spreadRadius: 6.0,
                                  offset: const Offset(0.0, 0.0), // shadow direction: bottom right
                                )
                              ],
                              borderRadius: const BorderRadius.all(Radius.circular(8.0)
                              ),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              Container(
                                margin: const EdgeInsets.only(left: 2.0, right: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2.0, right: 2.0, top: 2.0, bottom: 2.0),
                                      child: Row(
                                        children: [
                                          AutoSizeText(
                                            "Wallet daemon status",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                            minFontSize: 2.0,
                                          ),
                                          const SizedBox(
                                            width: 3.0,
                                          ),
                                          Icon(
                                            Icons.circle,
                                            size: 7.0,
                                            color: snapshot.data!.block! ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2.0, right: 2.0, top: 2.0, bottom: 2.0),
                                      child: Row(
                                        children: [
                                          AutoSizeText(
                                            "Staking daemon status",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                            minFontSize: 2.0,
                                          ),
                                          const SizedBox(
                                            width: 3.0,
                                          ),
                                          Icon(
                                            Icons.circle,
                                            size: 7.0,
                                            color: snapshot.data!.blockStake! ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2.0, right: 2.0, top: 2.0, bottom: 2.0),
                                      child: Row(
                                        children: [
                                          AutoSizeText(
                                            "Staking active",
                                            style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                            minFontSize: 2.0,
                                          ),
                                          const SizedBox(
                                            width: 3.0,
                                          ),
                                          Icon(
                                            Icons.circle,
                                            size: 7.0,
                                            color: snapshot.data!.stakingActive! ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0), color: Colors.black12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AutoSizeText(
                                          "Blockcount: ${snapshot.data?.blockCount ?? 0}",
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                          minFontSize: 2.0,
                                        ),
                                        const SizedBox(
                                          width: 5.0,
                                        ),
                                        AutoSizeText(
                                          "| Masternode count: ${snapshot.data?.masternodeCount ?? 0}",
                                          style: Theme.of(context).textTheme.headline5!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                          minFontSize: 2.0,
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                            ]),
                          );
                        }),
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
    if (hour >= 0 && hour < 6) {
      return AppLocalizations.of(context)!.good_night.capitalize();
    } else if (hour >= 6 && hour < 12) {
      return AppLocalizations.of(context)!.good_morning.capitalize();
    } else if (hour >= 12 && hour < 18) {
      return AppLocalizations.of(context)!.good_afternoon.capitalize();
    } else if (hour >= 18 && hour < 24) {
      return AppLocalizations.of(context)!.good_evening.capitalize();
    } else {
      return AppLocalizations.of(context)!.good_day.capitalize();
    }
  }
}
