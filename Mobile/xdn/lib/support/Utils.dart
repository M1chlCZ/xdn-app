import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


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

  
}