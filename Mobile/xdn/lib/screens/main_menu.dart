import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/generated/phone.pbgrpc.dart';
import 'package:digitalnote/models/StealhBalance.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/screens/addrScreen.dart';
import 'package:digitalnote/screens/masternode_screen.dart';
import 'package:digitalnote/screens/message_detail_screen.dart';
import 'package:digitalnote/screens/message_screen.dart';
import 'package:digitalnote/screens/settingsScreen.dart';
import 'package:digitalnote/screens/stakingScreen.dart';
import 'package:digitalnote/screens/stealth_screen.dart';
import 'package:digitalnote/screens/token_screen.dart';
import 'package:digitalnote/screens/voting_screen.dart';
import 'package:digitalnote/screens/walletscreen.dart';
import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/LifecycleWatcherState.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/barcode_scanner.dart';
import 'package:digitalnote/support/daemon_status.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:digitalnote/widgets/AvatarPicker.dart';
import 'package:digitalnote/widgets/BackgroundWidget.dart';
import 'package:digitalnote/widgets/balanceCard.dart';
import 'package:digitalnote/widgets/balance_card.dart';
import 'package:digitalnote/widgets/balance_stealth_card.dart';
import 'package:digitalnote/widgets/balance_token_card.dart';
import 'package:digitalnote/widgets/masternode_menu_widget.dart';
import 'package:digitalnote/widgets/send_qr_dialog.dart';
import 'package:digitalnote/widgets/small_menu_tile.dart';
import 'package:digitalnote/widgets/staking_menu_widget.dart';
import 'package:digitalnote/widgets/voting_menu_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
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
  final GlobalKey<BalanceStealthCardMenuState> _keyStealthBal = GlobalKey();
  ComInterface cm = ComInterface();

  FutureOr<Map<String, dynamic>>? _getBalance;

  Future<Map<String, dynamic>>? _getTokenBalance;

  Future<StealthBalance?>? _getStealthBalance;

  String? name;

  Map<String, dynamic>? _priceData;

  SessionStatus? session;

  bool contestActive = false;
  bool mnActive = false;
  bool stealthActive = false;

  Future<DaemonStatus>? daemonStatus;

  AppDatabase db = GetIt.I.get<AppDatabase>();

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  late final AnimationController _controller2 = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  late final Animation<double> _animation2 = CurvedAnimation(
    parent: _controller2,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    _getLocale();
    super.initState();
    loginDao();
    getNotification();
    FlutterAppBadger.removeBadge();
    getMNPermission();
  }

  getMNPermission() async {
    final channel = ClientChannel('194.60.201.213', port: 6805, options: const ChannelOptions(credentials: ChannelCredentials.insecure()));
    final stub = AppServiceClient(channel);

    try {
      String? token = await SecureStorage.read(key: globals.TOKEN_DAO);
      var response = await stub.userPermission(UserPermissionRequest()..code = 200, options: CallOptions(metadata: {'authorization': token ?? ""}));

      if (response.mnPermission) {
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            mnActive = true;
          });
          _controller.forward();
        });
      }
      if (response.stealthPermission) {
        Future.delayed(const Duration(milliseconds: 400), () {
          setState(() {
            stealthActive = true;
          });
          _controller2.forward();
        });
      }
    } catch (e) {
      Future.delayed(const Duration(seconds: 5), () {
        getMNPermission();
      });
    }
    await channel.shutdown();
  }

  void loginDao() async {
    refreshBalance();
    getInfo();
    getPriceData();
    String? s = await SecureStorage.read(key: globals.TOKEN_DAO);
    if (s != null) {
      print(s);
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

  getNotification() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      if (initialMessage.data['func'] == "sendMessage") {
        String sentAddr = initialMessage.data['fr'];
        String? contact = await db.getContactNameByAddr(sentAddr);
        MessageGroup m = MessageGroup(sentAddr: contact ?? sentAddr, sentAddressOrignal: sentAddr);
        if (mounted) Navigator.pushNamed(context, MessageDetailScreen.route, arguments: m);
        return;
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      if (message.data['func'] == "sendMessage") {
        String sentAddr = message.data['fr'];
        String? contact = await db.getContactNameByAddr(sentAddr);
        MessageGroup m = MessageGroup(sentAddr: contact ?? sentAddr, sentAddressOrignal: sentAddr);
        if (mounted) Navigator.pushNamed(context, MessageDetailScreen.route, arguments: m);
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
    NetInterface.getAddrBook();
  }

  void _getLocale() async {
    // var timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    // await SecureStorage.write(key: globals.LOCALE, value: timeZoneName);
  }

  refreshBalance() {
    _getBalance = NetInterface.getBalance(details: true);
    _getTokenBalance = NetInterface.getTokenBalance();
    _getStealthBalance = NetInterface.getStealthBalance();
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

  void gotoStealthScreen() {
    Navigator.of(context).pushNamed(StealthScreen.route, arguments: "nothing");
  }

  void gotoSettingsScreen() {
    Navigator.of(context).pushNamed(SettingsScreen.route, arguments: "shit");
    // Dialogs.openAlertBox(context, "header", "\nNot yet implemented\n");
  }

  void gotoMasternodeScreen() {
    Navigator.of(context).pushNamed(MasternodeScreen.route, arguments: "shit").then((value) => refreshBalance());
  }

  Future<DaemonStatus> getDaemonStatus() async {
    try {
      Map<String, dynamic> req = await cm.get("/status", serverType: ComInterface.serverGoAPI, debug: true);
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
                              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white54),
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
                                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 14.0),
                                    ),
                                    Text(name ?? '', style: Theme.of(context).textTheme.headlineSmall),
                                    const SizedBox(
                                      height: 2.0,
                                    ),
                                    InkWell(
                                      splashColor: Colors.white24,
                                      onTap: () {
                                        Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, "Tips, Rains, Thunder directly from the app. Coming soon!");
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(7.0),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(10.0),
                                          border: Border.all(color: Colors.white24, width: 1.0),
                                        ),
                                        child: Image.asset(
                                          "images/socials_general.png",
                                          height: 28.0,
                                          width: 28.0,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
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
                          scan: scanQR,
                        ),
                        SizeTransition(
                          sizeFactor: _animation2,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10.0,
                              ),
                              SizedBox(
                                height: mnActive ? 90.0 : 0.0,
                                child: BalanceStealthCardMenu(
                                  key: _keyStealthBal,
                                  getBalanceFuture: _getStealthBalance,
                                  goto: gotoStealthScreen,
                                ),
                              ),
                            ],
                          ),
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
                        SizeTransition(
                          sizeFactor: _animation,
                          child: SizedBox(
                            height: mnActive ? 90.0 : 0.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MasternodeMenuWidget(
                                  goto: gotoMasternodeScreen,
                                ),
                              ],
                            ),
                          ),
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
                                colors: [Color(0xFF333A57), Color(0xFF2C334E)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10.0,
                                  spreadRadius: 6.0,
                                  offset: const Offset(0.0, 0.0), // shadow direction: bottom right
                                )
                              ],
                              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
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
                                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
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
                                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
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
                                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
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
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.black12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AutoSizeText(
                                          "Blockcount: ${snapshot.data?.blockCount ?? 0}",
                                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
                                          minFontSize: 2.0,
                                        ),
                                        const SizedBox(
                                          width: 5.0,
                                        ),
                                        AutoSizeText(
                                          "| Masternode count: ${snapshot.data?.masternodeCount ?? 0}",
                                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 8.0, letterSpacing: 0.5),
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

  void scanQR() async {
    Map<String, String?> data = {};
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
      return BarcodeScanner(
        scanResult: (String s) {
          data = _splitString(s);
        },
      );
    }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    }));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (data.isNotEmpty) {
        processData(data);
      }
    });
  }

  void processData(Map<String, String?> data) {
    if (data["justAddress"] != null && data["address"] != null) {
      Dialogs.openQRAmountBot(context, data["address"]!, (amount, addr) {
        data["amount"] = amount;
        Navigator.of(context).pop();
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return SendDialogQR(
                data: data,
                priceData: _priceData,
                sendCoins: sendCoints,
              );
            });
      });
    } else if (data["loginqr"] != null) {
      Future.delayed(Duration.zero, () async {
        try {
          ComInterface interface = ComInterface();
          var tok = data["loginqr"];
          await interface.post("/login/qr/auth", body: {"token": tok}, serverType: ComInterface.serverGoAPI, debug: true);
          if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.alert, "Login successful");
        } catch (e) {
          debugPrint(e.toString());
        }
      });
    } else if (data["error"] == null) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SendDialogQR(
              data: data,
              priceData: _priceData,
              sendCoins: sendCoints,
            );
          });
    } else {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, data["error"]!);
    }
  }

  void sendCoints(Map<String, String?> data) {
    try {
      Navigator.of(context).pop();
      String method = "/user/send";
      Map<String, dynamic>? m;
      ComInterface interface = ComInterface();
      Dialogs.openWaitBox(context);
      var addr = data["address"]!;
      var recipient = data["message"];
      var amnt = data["amountCrypto"]!;

      if (!RegExp(r"^\b(d)[a-zA-Z0-9]{33}$").hasMatch(addr)) {
        throw Exception("Invalid address");
      }

      if (recipient == null) {
        m = {
          "address": addr,
          "amount": double.parse(double.parse(amnt).toStringAsFixed(8)),
        };
      } else {
        method = "/user/send/contact";
        m = {
          "address": addr,
          "amount": double.parse(double.parse(amnt).toStringAsFixed(8)),
          "contact": recipient,
        };
      }
      Future.delayed(const Duration(milliseconds: 100), () async {
        await interface.post(method, body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
        if (mounted) {
          Navigator.of(context).pop();
          Dialogs.openAlertBox(context, AppLocalizations.of(context)!.notice_warn, AppLocalizations.of(context)!.succ);
        }
      });
    } catch (e) {
      Navigator.of(context).pop();
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, e.toString());
    }
  }

  Map<String, String?> _splitString(String string) {
    Map<String, String?> data = {};
    RegExp regex = RegExp(r"^\b(d)[a-zA-Z0-9]{33}$");
    if (string.split(":").length > 1) {
      var split = string.split(":");
      var split2 = split[1].split("?");
      if (regex.hasMatch(split2[0])) {
        data["name"] = split[0];
        data["address"] = split2[0];
        var split3 = split2[1].split("&");
        if (split3.isNotEmpty) {
          data[split3[0].split("=")[0]] = split3[0].split("=")[1];
        }
        if (split3.length > 1) {
          data[split3[1].split("=")[0]] = split3[1].split("=")[1];
        }
        if (split3.length > 2) {
          data[split3[2].split("=")[0]] = split3[2].split("=")[1];
        }
      } else {
        return {"error": "Invalid QR code"};
      }
    } else {
      var split = string.split(";");
      if (split[0] == "loginqr") {
        var m = {"loginqr": split[1]};
        return m;
      }
      var match = regex.firstMatch(string);
      if (match != null) {
        data["address"] = match.group(0);
        data["justAddress"] = "true";
        return data;
      } else {
        return {"error": "Invalid QR code"};
      }
    }

    if (data["name"]?.toLowerCase() != "digitalnote") {
      return {"error": "Invalid QR code"};
    }
    if (data["address"] == null || data["address"]!.isEmpty) {
      return {"error": "Invalid QR code"};
    }

    if (data["amount"] == null || data["amount"]!.isEmpty) {
      return {"error": "Invalid QR code"};
    }

    data["error"] = null;
    return data;
  }
}
