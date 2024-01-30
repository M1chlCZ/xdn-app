import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/barcode_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../models/Contact.dart';
import '../support/AppDatabase.dart';
import '../support/ColorScheme.dart';
import '../support/Dialogs.dart';
import '../support/NetInterface.dart';
import '../support/Utils.dart';

class SendWidget extends StatefulWidget {
  final Function? func;
  final VoidCallback cancel;

  const SendWidget({super.key, this.func, required this.cancel});

  @override
  SendWidgetState createState() => SendWidgetState();
}

const textFieldPadding = EdgeInsets.all(8.0);
const textFieldTextStyle = TextStyle(fontSize: 18.0);

class SendWidgetState extends State<SendWidget> {
  final TextEditingController _controllerAddress = TextEditingController();
  final TextEditingController _controllerAmount = TextEditingController();

  final GlobalKey _textFieldAmountKey = GlobalKey();

  double? _balance = 0.0;

  Map<String, dynamic>? _priceData;

  bool succ = false;
  bool fail = false;
  bool wait = false;
  bool sendView = true;
  Contact? _recipient;

  void _sendConfirmation() async {
    Dialogs.openSendConfirmBox(context, _sendCoins);
  }

  void _sendCoins() async {
    Navigator.of(context).pop();
    try {
      String method = "/user/send";
      String addr = _controllerAddress.text;
      String amnt = _controllerAmount.text;
      Map<String, dynamic>? m;
      if (double.parse(amnt) > _balance!) {
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, "${AppLocalizations.of(context)!.st_insufficient}!");
        return;
      }

      if (double.parse(amnt) == 0.0) {
        if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.amount_empty);
        return;
      }

      if (!RegExp(r"^\b(d)[a-zA-Z0-9]{33}$").hasMatch(addr)) {
        if (_recipient != null) {
          addr = _recipient!.addr!;
        } else {
          if (mounted) Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.konj_addr_invalid);
          return;
        }
      }
      setState(() {
        wait = true;
        succ = false;
        fail = false;
        sendView = false;
      });

      if (_recipient == null) {
        m = {
          "address": addr,
          "amount": double.parse(amnt),
        };
      } else {
        method = "/user/send/contact";
        m = {
          "address": addr,
          "amount": double.parse(amnt),
          "contact": _recipient!.name,
        };
      }

      ComInterface interface = ComInterface();
      await interface.post(method, body: m, serverType: ComInterface.serverGoAPI, type: ComInterface.typeJson, debug: false);
      setState(() {
        wait = false;
        succ = true;
        fail = false;
        sendView = false;
        widget.func!();
      });

      Future.delayed(const Duration(seconds: 2), () {
        initView();
      });
    } on TimeoutException catch (_) {
      setState(() {
        succ = false;
        fail = true;
        wait = false;
        sendView = false;
      });
      widget.func!();
    } on SocketException catch (_) {
      setState(() {
        succ = false;
        fail = true;
        wait = false;
        sendView = false;
      });
      widget.func!();
    } catch (e) {
      setState(() {
        succ = false;
        fail = true;
        wait = false;
        sendView = false;
      });
      widget.func!();
    }
  }

  void displayDialog(context, title, text) => showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(title), content: Text(text)),
      );

  void initView() {
    setState(() {
      wait = false;
      succ = false;
      fail = false;
      sendView = true;
      widget.func!();
      _controllerAmount.clear();
      _controllerAddress.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentBalance();
    getPriceData();
    if (kDebugMode) {
      setState(() {
        _controllerAddress.text = "dcjvrzkNmPCV8f2e2C9UVB5wTroo4iELzt";
      });
    }
  }

  getPriceData() async {
    _priceData = await NetInterface.getPriceData();
    setState(() {});
  }

  void _getCurrentBalance() async {
    await Future.delayed(const Duration(seconds: 2), () async {
      var result = await NetInterface.getBalance(details: true);
      setState(() {
        _balance = double.parse(result!['spendable'].toString());
      });
    });
  }

  void _openQRScanner() async {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
      return BarcodeScanner(
        scanResult: (String s) {
          _splitString(s);
        },
      );
    }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    }));
  }

  void processData(Map<String, String?> data) {
    if (data["justAddress"] != null && data["address"] != null) {
      _controllerAddress.text = data["address"]!;
    } else if (data["error"] == null) {
      double? currencyAmount = _priceData?[data["label"]?.toLowerCase()];
      if (data["amount"] == null) {
        data["amountCrypto"] = "0.0";
      } else if (currencyAmount == null) {
        var amountXDN = double.parse(data["amount"]!);
        _controllerAmount.text = amountXDN.toString();
      } else {
        var amountXDN = double.parse(data["amount"]!) / currencyAmount;
        _controllerAmount.text = amountXDN.toString();
      }
      _controllerAddress.text = data["address"]!;
      data["amount"]!;
    } else {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, data["error"]!);
    }
  }

  _splitString(String string) {
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
        processData({"error": "Invalid QR code"});
        return {"error": "Invalid QR code"};
      }
    } else {
      var match = regex.firstMatch(string);
      if (match != null) {
        data["address"] = match.group(0);
        data["justAddress"] = "true";
        data["error"] = null;
        processData(data);
        return data;
      } else {
        processData({"error": "Invalid QR code"});
        return {"error": "Invalid QR code"};
      }
    }

    if (data["name"]?.toLowerCase() != "digitalnote") {
      processData({"error": "Invalid QR code"});
      return {"error": "Invalid QR code"};
    }
    if (data["address"] == null || data["address"]!.isEmpty) {
      processData({"error": "Invalid QR code"});
      return {"error": "Invalid QR code"};
    }

    if (data["amount"] == null || data["amount"]!.isEmpty) {
      processData({"error": "Invalid QR code"});
      return {"error": "Invalid QR code"};
    }
    data["error"] = null;
    processData(data);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    var padding = 50.0;
    var heightVal = MediaQuery.of(context).size.height * 0.3;
    final bool useTablet = Utils.isTablet(MediaQuery.of(context));
    return Stack(children: [
      Visibility(
        visible: succ,
        child: Container(
          height: useTablet ? heightVal : 220.0,
          margin: EdgeInsets.only(top: useTablet ? padding : 10.0, left: 10.0, right: 10.0),
          padding: const EdgeInsets.all(10.0),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF222D52), Color(0xFF384F91)],
              ),
              border: Border.all(color: Colors.green),
              borderRadius: const BorderRadius.all(Radius.circular(15.0))),
          child: Center(
              child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              child: AutoSizeText(
                '${AppLocalizations.of(context)!.succ}!',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 48.0),
                minFontSize: 8,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )),
        ),
      ),
      Visibility(
        visible: wait,
        child: Container(
          height: useTablet ? heightVal : 220.0,
          margin: EdgeInsets.only(top: useTablet ? padding : 10.0, left: 10.0, right: 10.0),
          padding: const EdgeInsets.all(10.0),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Theme.of(context).konjCardColor, border: Border.all(color: Colors.transparent), borderRadius: const BorderRadius.all(Radius.circular(15.0))),
          child: Center(
              child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              child: AutoSizeText(
                AppLocalizations.of(context)!.send_wait,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 48.0),
                minFontSize: 8,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )),
        ),
      ),
      Visibility(
        visible: fail,
        child: Container(
          height: useTablet ? heightVal : 220.0,
          margin: EdgeInsets.only(top: useTablet ? padding : 10.0, left: 10.0, right: 10.0),
          padding: const EdgeInsets.all(10.0),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: const Color(0xFFF77066), border: Border.all(color: Colors.red), borderRadius: const BorderRadius.all(Radius.circular(15.0))),
          child: Center(
              child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              child: AutoSizeText(
                '${AppLocalizations.of(context)!.st_insufficient}!',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 48.0),
                minFontSize: 8,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )),
        ),
      ),
      Visibility(
        visible: sendView,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.only(top: useTablet ? padding : 0.0, left: 11.0, right: 11.0),
            child: PhysicalModel(
              color: Theme.of(context).konjCardColor,
              shadowColor: Colors.black45,
              elevation: 5,
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              child: Container(
                height: useTablet ? heightVal : 225.0,
                padding: const EdgeInsets.all(10.0),
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                    image: DecorationImage(image: AssetImage("images/test_pattern.png"), fit: BoxFit.fill, opacity: 0.8),
                    gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                      colors: [Color(0xFF222D52), Color(0xFF384F91)],
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(15.0),
                    )),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: <Widget>[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: TypeAheadField(
                                suggestionsBoxDecoration: SuggestionsBoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  color: Theme.of(context).konjTextFieldHeaderColor,
                                ),
                                noItemsFoundBuilder: (context) {
                                  return const SizedBox(width: 0, height: 0);
                                },
                                textFieldConfiguration: TextFieldConfiguration(
                                  maxLength: 40,
                                  maxLines: 1,
                                  controller: _controllerAddress,
                                  autofocus: false,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                  decoration: InputDecoration(
                                    counterText: "",
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white60, width: 1.0), borderRadius: BorderRadius.circular(15.0)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12, width: 1.0), borderRadius: BorderRadius.circular(15.0)),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    contentPadding: const EdgeInsets.only(left: 14.0),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    hoverColor: Colors.white60,
                                    focusColor: Colors.white60,
                                    labelStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white),
                                    hintText: '${AppLocalizations.of(context)!.address} / ${AppLocalizations.of(context)!.contact}',
                                    hintStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 16.0, color: Colors.white),
                                  ),
                                ),
                                suggestionsCallback: (pattern) async {
                                  return await AppDatabase().searchContact(pattern);
                                },
                                itemBuilder: (context, suggestion) {
                                  var cont = suggestion as Contact?;
                                  return Column(
                                    children: [
                                      ListTile(
                                        tileColor: Colors.transparent,
                                        title: SizedBox(
                                          width: 150,
                                          child: AutoSizeText(
                                            cont!.getName()!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                        ),
                                        subtitle: SizedBox(
                                          width: 150,
                                          child: AutoSizeText(
                                            cont.getAddr()!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                        child: SizedBox(
                                          height: 1,
                                          child: Container(color: Colors.white.withOpacity(0.2)),
                                        ),
                                      )
                                    ],
                                  );
                                },
                                onSuggestionSelected: (suggestion) {
                                  _recipient = suggestion as Contact?;
                                  _controllerAddress.text = _recipient!.getName()!;
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10.0,
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: TextButton.icon(
                                icon: const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.qr_code_sharp,
                                    color: Colors.white,
                                  ),
                                ),
                                label: Text('QR  ', style: Theme.of(context).textTheme.bodyMedium),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.resolveWith((states) => qrColors(states)),
                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)))),
                                onPressed: () => _openQRScanner(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                key: _textFieldAmountKey,
                                controller: _controllerAmount,
                                keyboardType: Platform.isIOS ? const TextInputType.numberWithOptions(signed: true) : TextInputType.number,
                                maxLength: 40,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                                ],
                                autofocus: false,
                                style: Theme.of(context).textTheme.headlineSmall,
                                decoration: InputDecoration(
                                  counterText: "",
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12, width: 1.0), borderRadius: BorderRadius.circular(15.0)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1.0), borderRadius: BorderRadius.circular(15.0)),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  contentPadding: const EdgeInsets.only(left: 14.0),
                                  labelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                                  hintText: AppLocalizations.of(context)!.amount,
                                  hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16.0, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: TextButton.icon(
                                icon: const Icon(
                                  Icons.arrow_upward_sharp,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'MAX   ',
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16.0),
                                ),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.resolveWith((states) => amountColors(states)),
                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)))),
                                onPressed: () async {
                                  Map<String, dynamic>? ss = await NetInterface.getBalance(details: true);
                                  _balance = double.parse(ss!["spendable"].toString());
                                  double max = _balance! - 0.001;
                                  _controllerAmount.text = max.toString();
                                  _controllerAmount.selection = TextSelection.fromPosition(TextPosition(offset: _controllerAmount.text.length));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: SizedBox(
                          height: 50,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextButton.icon(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: AutoSizeText(
                                      AppLocalizations.of(context)!.cancel.toUpperCase(),
                                      maxLines: 1,
                                      minFontSize: 8,
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0),
                                    ),
                                    style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.resolveWith((states) => cancelColors(states)),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)))),
                                    onPressed: () {
                                      widget.cancel();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20.0,
                              ),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: TextButton.icon(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_sharp,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    label: AutoSizeText(
                                      AppLocalizations.of(context)!.send.toUpperCase(),
                                      maxLines: 1,
                                      minFontSize: 8,
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14.0),
                                    ),
                                    style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.resolveWith((states) => sendColors(states)),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)))),
                                    onPressed: () {
                                      _sendConfirmation();
                                    },
                                    onLongPress: () {
                                      _sendConfirmation();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ]),
      ),
    ]);
  }
}

Color qrColors(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.blue;
  }
  return Colors.white10;
}

Color amountColors(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.blue;
  }
  return Colors.white10;
}

Color sendColors(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.blue;
  }
  return Colors.white10;
}

Color cancelColors(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.blue;
  }
  return Colors.redAccent;
}
