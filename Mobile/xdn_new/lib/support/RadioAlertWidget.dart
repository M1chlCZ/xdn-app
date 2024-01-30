
import 'package:digitalnote/support/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digitalnote/main.dart';
import '../globals.dart' as globals;

class RadioAlertWidget extends StatefulWidget {
  final Function(int value) func;

  const RadioAlertWidget({super.key, required this.func});

  @override
  RadioAlertState createState() => RadioAlertState();
}

class RadioAlertState extends State<RadioAlertWidget> {
  int _crtIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) async {
      if (mounted) {
        final Locale appLocale = Localizations.localeOf(context);
        var i = globals.LANGUAGES_CODES
            .indexWhere((element) => element.contains(appLocale.toString()));
        if (i != -1) {
          setState(() {
            _crtIndex = i;
          });
        } else {
          setState(() {
            _crtIndex = 0;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: ListView(shrinkWrap: false, children: _getList()),
    );
  }

  List<RadioListTile> _getList() {
    List<RadioListTile> l = [];
    for (var i = 0; i < globals.LANGUAGES.length; i++) {
      l.add(RadioListTile(
          value: i,
          groupValue: _crtIndex,
          title: Text(
            globals.LANGUAGES[i],
            style: GoogleFonts.montserrat(
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.normal,
                fontSize: 16,
                color: Colors.white70),
          ),
          activeColor: Colors.amber,
          onChanged: (val) {
            setState(() {
              _crtIndex = val;
              Locale l;
              var ls = globals.LANGUAGES_CODES[val].split('_');
              if(ls.length == 1) {
                l = Locale(ls[0], '');
              }else if(ls.length == 2) {
                l = Locale(ls[0], ls[1]);
              }else{
                l = Locale.fromSubtags(countryCode: ls[2], scriptCode: ls[1], languageCode: ls[0]);
              }
              MyApp.of(context)?.setLocale(l);
              SecureStorage.write(key: globals.LOCALE_APP, value: globals.LANGUAGES_CODES[val]);
            });
          }));
    }
    return l;
  }
}
