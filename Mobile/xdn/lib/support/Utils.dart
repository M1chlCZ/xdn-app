import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';


class Utils {
  static bool isTablet(MediaQueryData query) {
    var size = query.size;
    var diagonal =
    sqrt((size.width * size.width) + (size.height * size.height));
    var isTablet = diagonal > 1100.0;
    return isTablet;
  }

  static String convertDate(String? d) {
    if(d == null) return "";
    DateTime dt = DateTime.now();
    int offset = dt.timeZoneOffset.inHours;
    var date = DateTime.parse(d).toLocal();
    var newDate = DateTime(date.year, date.month, date.day,
        date.hour + offset, date.minute, date.second);
    var format = DateFormat.yMMMMd(Platform.localeName).add_jm();
    return format.format(newDate);
  }

  static DateTime convertDateTime(String? d) {
    String nullDate = "1970-00-01 00:00:01";
    if(d == null) return DateTime.parse(nullDate);
    DateTime dt = DateTime.now();
    int offset = dt.timeZoneOffset.inHours;
    var date = DateTime.parse(d).toLocal();
    var newDate = DateTime(date.year, date.month, date.day,
        date.hour + offset, date.minute, date.second);
    var format = DateFormat.yMMMMd(Platform.localeName).add_jm();
    return newDate;
  }

  static String convertDateTimeMessage(String? d) {
    String nullDate = "1970-00-01 00:00:01";
    if(d == null) return DateTime.parse(nullDate).toIso8601String();
    DateTime dt = DateTime.now();
    int offset = dt.timeZoneOffset.inHours * -1;
    var date = DateTime.parse(d).toLocal();
    var newDate = DateTime(date.year, date.month, date.day,
        date.hour + offset, date.minute, date.second);
    return newDate.toIso8601String();
  }


  static String getMeDate(String d, BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    var date = DateTime.parse(d).toLocal();
    var format = DateFormat.MMMMd(locale);
    return format.format(date);
  }

  static void openLink(String? s) async {
    var succ = false;
    if (s != null) {
      try {
        succ = await launchUrl(Uri.parse(s), mode: LaunchMode.externalNonBrowserApplication);
      } catch (e) {
        debugPrint(e.toString());
      }
      if (!succ) {
        try {
          succ = await launchUrl(Uri.parse(s), mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      if (!succ) {
        try {
          await launchUrl(Uri.parse(s), mode: LaunchMode.platformDefault);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }
  }

  static String formatWallet(String s) {
    var firstPart = s.substring(0,5);
    var lastPart = s.substring(s.length - 3);
    return "$firstPart...$lastPart";
  }

  static String getUTC() {
    var dateTime = DateTime.now();
    var date = DateFormat('yyyy-MM-dd').format(dateTime);
    var dateZero = "$date 00:00:00";
    var val = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS")
        .format(DateTime.parse(dateZero));
    var offset = dateTime.timeZoneOffset;
    var hours =
    offset.inHours > 0 ? offset.inHours : 1; // For fixing divide by 0
    if (!offset.isNegative) {
      val = "$val+${offset.inHours.toString().padLeft(2, '0')}:${(offset.inMinutes % (hours * 60)).toString().padLeft(2, '0')}";
    } else {
      val = "$val-${(-offset.inHours).toString().padLeft(2, '0')}:${(offset.inMinutes % (hours * 60)).toString().padLeft(2, '0')}";
    }
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(val));
  }

 static String formatBalance(double number) {
    NumberFormat nf = NumberFormat("##.###");
    if (number < 1000) {
      return nf.format(number).toString();
    } else if ((number / 1000) > 1 && (number / 1000) < 1000) {
      return '${nf.format(number / 1000)}k';
    } else if ((number / 1000000) > 1 && (number / 1000000) < 1000) {
      return '${nf.format(number / 1000000)}m';
    } else {
      return number.toString();
    }
  }

  static bool checkAddress (String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (_) {
      return false;
    }
  }
  
}