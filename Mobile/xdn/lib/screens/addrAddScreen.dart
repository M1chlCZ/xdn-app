import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:digitalnote/support/Dialogs.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/QCodeScanner.dart';
import 'package:digitalnote/support/RoundButton.dart';
import 'package:permission_handler/permission_handler.dart';

import '../support/CardHeader.dart';
import '../support/ColorScheme.dart';
import '../widgets/BackgroundWidget.dart';

class AddressAddScreen extends StatefulWidget {
  const AddressAddScreen({Key? key}) : super(key: key);

  @override
  AddressAddScreenState createState() => AddressAddScreenState();
}

class AddressAddScreenState extends State<AddressAddScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controllerAddr = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const BackgroundWidget(
        mainMenu: false,
        hasImage: true,
        image: "contactsicon.png",
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body:SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            CardHeader(title: AppLocalizations.of(context)!.contact_add, backArrow: true,),
              Container(
                margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                padding:
                const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0, bottom: 10.0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  color: Theme.of(context).konjHeaderColor,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10.0,),
                    TextField(
                      controller: _controller,
                      style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                      decoration: InputDecoration(
                        floatingLabelBehavior:
                        FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.all(8.0),
                        filled: true,
                        hoverColor: Colors.white24,
                        focusColor: Colors.white24,
                        fillColor: Theme.of(context).konjTextFieldHeaderColor,
                        labelText: "",
                        labelStyle: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white54, fontSize: 18.0),
                        hintText: AppLocalizations.of(context)!.name,
                        hintStyle: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white54, fontSize: 18.0),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.white70,
                        ),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                      ),
                    ),
                    const SizedBox(height: 20.0,),
                    Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: FractionallySizedBox(
                                widthFactor: 0.95,
                                child: SizedBox(
                                  height: 45,
                                  child: TextField(
                                    controller: _controllerAddr,
                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                                    decoration: InputDecoration(
                                      floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                      contentPadding: const EdgeInsets.all(8.0),
                                      filled: true,
                                      hoverColor: Colors.white24,
                                      focusColor: Colors.white24,
                                      fillColor: Theme.of(context).konjTextFieldHeaderColor,
                                      labelText: "",
                                      labelStyle: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white54, fontSize: 18.0),
                                      hintText: AppLocalizations.of(context)!.address,
                                      hintStyle: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white54, fontSize: 18.0),
                                      prefixIcon: const Icon(
                                        Icons.person,
                                        color: Colors.white70,
                                      ),
                                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 0.0, top: 1.0),
                              child: RoundButton(
                                  height: 40,
                                  width: 40,
                                  color: Theme.of(context).konjHeaderColor,
                                  onTap: () {
                                    _openQRScanner();
                                  },
                                  splashColor: Colors.black45,
                                  icon: const Icon(Icons.qr_code,size: 35, color: Colors.white70,)),
                            ),
                          ]),
                    const SizedBox(height: 10.0,),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: TextButton.icon(
                                  icon: const Icon(
                                    Icons.person_add,
                                    color: Colors.white70,
                                  ),
                                  label: Text(
                                    AppLocalizations.of(context)!.contact_add,
                                    style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                                  ),
                                  style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.resolveWith((states) => sendColors(states)),
                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: const BorderSide(color: Colors.transparent)))),
                                  onPressed: () {
                                    _saveUsers(_controller.text, _controllerAddr.text);

                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0,),
                  ],
                ),
              ),
          ]),
        ),
      )
    ],
    );
  }

  void _openQRScanner() async {
    FocusScope.of(context).unfocus();

    Future.delayed(const Duration(milliseconds: 500), () async {
      var status = await Permission.camera.status;
      if (await Permission.camera.isPermanentlyDenied) {
        await Dialogs.openAlertBoxReturn(context, AppLocalizations.of(context)!.warning, AppLocalizations.of(context)!.camera_perm);
        openAppSettings();
      } else if (status.isDenied) {
        var r = await Permission.camera.request();
        if (r.isGranted) {
          Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
            return QScanWidget(
              scanResult: (String s) {
              _controllerAddr.text = s;
              },
            );
          }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          }));
        }
      } else {
        Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
          return QScanWidget(
            scanResult: (String s) {
              _controllerAddr.text = s;
            },
          );
        }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        }));
      }
    });
  }

  void _saveUsers(String name, String addr) async {
    var i = await NetInterface.saveContact(name, addr, context);
    Navigator.of(context).pop();
    if (i == 1) {
      await NetInterface.getAddrBook();
      setState(() {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.contact_added),
          backgroundColor: const Color(0xFF63C9F3),
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      });
    }
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
}
