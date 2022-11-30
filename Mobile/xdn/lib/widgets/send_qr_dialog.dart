import 'package:digitalnote/widgets/button_flat.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SendDialogQR extends StatefulWidget {
  final String? img;
  final Map<String, String?> data;
  final Map<String, dynamic>? priceData;
  final Function(Map<String, String?>) sendCoins;

  const SendDialogQR({Key? key, this.img, required this.data, required this.priceData, required this.sendCoins}) : super(key: key);

  @override
  SendDialogQRState createState() => SendDialogQRState();
}

class SendDialogQRState extends State<SendDialogQR> {
  Map<String, String?> mapData = {};
  NumberFormat nf = NumberFormat("#,###.##", "en_US");
  double amountXDN = 0.0;
  String? error;

  @override
  void initState() {
    super.initState();
    mapData = widget.data;
    double? currencyAmount = widget.priceData![mapData["label"]!.toLowerCase()];
    if (currencyAmount == null) {
      error = "Unknown currency";
    } else {
      amountXDN = double.parse(mapData["amount"]!) / currencyAmount;
      mapData["amountCrypto"] = amountXDN.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.padding),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  contentBox(context) {
    return Stack(
      children: <Widget>[
        if (error == null)
          Container(
            padding: const EdgeInsets.only(left: Constants.padding, top: Constants.avatarRadius + Constants.padding, right: Constants.padding, bottom: Constants.padding),
            margin: const EdgeInsets.only(top: Constants.avatarRadius),
            decoration: BoxDecoration(shape: BoxShape.rectangle, color: Colors.white, borderRadius: BorderRadius.circular(Constants.padding), boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
            ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Send transaction",
                  style: GoogleFonts.aBeeZee(fontSize: 14, fontWeight: FontWeight.w200, color: Colors.black.withOpacity(0.8)),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "${mapData["amount"] ?? ''} ${mapData["label"] ?? ''}",
                  style: GoogleFonts.aBeeZee(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.8)),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  "XDN Amount",
                  style: GoogleFonts.aBeeZee(fontSize: 12, fontWeight: FontWeight.w200, color: Colors.black.withOpacity(0.6)),
                ),
                Text(
                  "${nf.format(amountXDN)} XDN",
                  style: GoogleFonts.aBeeZee(fontSize: 14, fontWeight: FontWeight.w200, color: Colors.black.withOpacity(0.8)),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "Message",
                  style: GoogleFonts.aBeeZee(fontSize: 12, fontWeight: FontWeight.w200, color: Colors.black.withOpacity(0.6)),
                ),
                Text(
                  mapData['message'] ?? '',
                  style: GoogleFonts.aBeeZee(fontSize: 14, fontWeight: FontWeight.w200, color: Colors.black.withOpacity(0.8)),
                ),
                const SizedBox(
                  height: 45,
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FlatCustomButton(
                            width: 100,
                            height: 35,
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "No",
                              style: TextStyle(fontSize: 18),
                            )),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: FlatCustomButton(
                            width: 100,
                            height: 35,
                            color: Colors.lightGreen,
                            onTap: () {
                              widget.sendCoins(mapData);
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Yes",
                              style: TextStyle(fontSize: 18),
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (error != null)
          Container(
            width: 300,
            padding: const EdgeInsets.only(left: Constants.padding, top: Constants.avatarRadius + Constants.padding, right: Constants.padding, bottom: Constants.padding),
            margin: const EdgeInsets.only(top: Constants.avatarRadius),
            decoration: BoxDecoration(shape: BoxShape.rectangle, color: Colors.red, borderRadius: BorderRadius.circular(Constants.padding), boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
            ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Error",
                  style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  "${error ?? ''}!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        Positioned(
          left: Constants.padding,
          right: Constants.padding,
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 2), blurRadius: 10),
            ]),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF18254E),
              radius: Constants.avatarRadius,
              child: Image.asset(
                widget.img ?? "images/logo_send.png",
                width: Constants.avatarRadius * 1.5,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Constants {
  Constants._();

  static const double padding = 20.0;
  static const double avatarRadius = 45.0;
}
