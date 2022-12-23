import 'dart:io';

import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/auto_size_text_field.dart';
import 'package:digitalnote/support/barcode_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SendStealthWidget extends StatefulWidget {
  final double? balance;
  final Function(String address, String amount) send;
  final String address;

  const SendStealthWidget({Key? key, this.balance, required this.send, required this.address}) : super(key: key);

  @override
  State<SendStealthWidget> createState() => _SendStealthWidgetState();
}

class _SendStealthWidgetState extends State<SendStealthWidget> {
  final GlobalKey _textFieldAmountKey = GlobalKey();
  final TextEditingController _controllerAmount = TextEditingController();
  final TextEditingController _controllerAddress = TextEditingController();

  Map<String, dynamic>? _priceData = {};
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  getPriceData() async {
    _priceData = await NetInterface.getPriceData();
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        image: const DecorationImage(
          image: AssetImage("images/test_pattern.png"),
          fit: BoxFit.cover,
          opacity: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 4,
            blurRadius: 15,
            offset: const Offset(0, 5), // changes position of shadow
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: AutoSizeTextField(
                        controller: _controllerAddress,
                        keyboardType: Platform.isIOS ? const TextInputType.numberWithOptions(signed: true) : TextInputType.number,
                        maxLines: 1,
                        minFontSize: 10,
                        stepGranularity: 0.1,
                        autofocus: false,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: InputDecoration(
                          counterText: "",
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12, width: 1.0), borderRadius: BorderRadius.circular(15.0)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30, width: 1.0), borderRadius: BorderRadius.circular(15.0)),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.only(left: 14.0),
                          labelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                          hintText: AppLocalizations.of(context)!.address,
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
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: AutoSizeTextField(
                        key: _textFieldAmountKey,
                        controller: _controllerAmount,
                        keyboardType: Platform.isIOS ? const TextInputType.numberWithOptions(signed: true) : TextInputType.number,
                        maxLength: 40,
                        maxLines: 1,
                        minFontSize: 10,
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
                      textDirection: TextDirection.rtl,
                      child: TextButton.icon(
                        icon: const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.white,
                          size: 28,
                        ),
                        label: Text(
                          '${AppLocalizations.of(context)!.send.toUpperCase()}   ',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16.0),
                        ),
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith((states) => amountColors(states)),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)))),
                        onPressed: ()  {
                          widget.send(_controllerAddress.text, _controllerAmount.text);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }

  Color amountColors(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.green;
    }
    return Colors.lightGreen;
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
}
