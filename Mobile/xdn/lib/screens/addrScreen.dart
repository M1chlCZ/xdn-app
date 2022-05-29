import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:konjungate/screens/addrAddScreen.dart';
import 'package:konjungate/support/MessageGroup.dart';
import 'package:konjungate/support/NetInterface.dart';

import '../globals.dart' as globals;
import '../screens/messageComposeScreen.dart';
import '../support/AppDatabase.dart';
import '../support/CardHeader.dart';
import '../support/ColorScheme.dart';
import '../support/Contact.dart';
import '../support/ContactTile.dart';
import '../support/Dialogs.dart';
import '../support/Encrypt.dart';
import '../support/RoundButton.dart';
import '../widgets/backgroundWidget.dart';
import 'messageDetailScreen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({Key? key}) : super(key: key);

  @override
  AddressScreenState createState() => AddressScreenState();
}

class AddressScreenState extends State<AddressScreen> {
  final TextEditingController _controller = TextEditingController();
  Contact? _tempContact;
  final storage = const FlutterSecureStorage();
  Future<List<Contact>>? _getUserFuture;
  String user = "";

  @override
  void initState() {
    super.initState();
    _getUserFuture = _getUsers();
  }

  void _openSelectBox(String name, String addr, Contact c) {
    _tempContact = c;
    Dialogs.openSelectContactDialog(context, addr, name, _openMessageSend, _openSendBox, _openContactShare);
  }

  void _openMessageSend({Contact? contact}) async {
    Navigator.of(context).pop();
    MessageGroup? l;
    if (contact == null) {
      l = await AppDatabase().getMessageGroupByAddr(_tempContact!.addr!);
    } else {
      l = await AppDatabase().getMessageGroupByAddr(contact.addr!);
    }

    if (l == null) {
      Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
        return MessageComposeScreen(
          cont: _tempContact,
        );
      }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
        return FadeTransition(opacity: animation, child: child);
      }));
    } else {
      Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
        return MessageDetailScreen(
          mgroup: l!,
        );
      }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
        return FadeTransition(opacity: animation, child: child);
      }));
    }
  }

  void _openContactShare() async {
    Navigator.of(context).pop();
    Dialogs.openSelectContactListDialog(context, _tempContact!.name!, _contactShareCallBack);
  }

  void _contactShareCallBack(Contact c) async {
    Navigator.of(context).pop();
    Dialogs.openWaitBox(context);
    var sharemessage = AppLocalizations.of(context)!.contact +' ' + _tempContact!.name! + ':';
    await NetInterface.sendMessage(c.addr!, sharemessage, 0);
    Future.delayed(const Duration(seconds: 3), () async {
      await NetInterface.sendMessage(c.addr!, _tempContact!.addr!, 0);
      Future.delayed(const Duration(seconds: 2), () async {
        await NetInterface.updateRead(c.addr!);
        Navigator.of(context).pop();
        _openMessageSend(contact: c);
      });
    });
  }

  void _openSendBox(String addr, String name) {
    Navigator.of(context).pop();
    Dialogs.openContactSendBox(context, name, addr, _sendBoxConfirmation);
  }

  void _openEditBox(Contact c) {
    Dialogs.openContactEditBox(context, c, _editBoxCallback);
  }

  void _editBoxCallback() {
    setState(() {
      _getUserFuture = _getUsers();
    });
  }

  void _sendBoxConfirmation(String amount, String name, String addr) async {
    Navigator.of(context).pop();
    Dialogs.openSendContactConfirmBox(context, name, addr, amount, _sendBoxCallback);
  }

  void _sendBoxCallback(String amount, String name, String addr) async {
    String? ss = await NetInterface.getBalance(details: true);
    var sjson = json.decode(ss!);
    double _balance = (double.parse(sjson["balance"]));
    Navigator.of(context).pop();
    if(double.parse(amount) > _balance) {
      Dialogs.openAlertBox(context, AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.st_insufficient + "!");
      return;

    }
    Dialogs.openWaitBox(context);
    try {
      if (amount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Amount cannot be empty!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      } else {
        const storage = FlutterSecureStorage();
        String? jwt = await storage.read(key: "jwt");
        String? id = await storage.read(key: globals.ID);
        String? user = await storage.read(key: globals.USERNAME);

        if (addr.length != 34 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(addr) || addr[0] != 'K') {
          Dialogs.displayDialog(context, "Error", "Invalid KONJ address");
          return;
        }

        Map<String, dynamic> m = {
          "Authorization": jwt,
          "User": user,
          "id": id,
          "request": "sendContactTransaction",
          "param1": addr,
          "param2": amount,
          "param3": name,
        };

        var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");
        final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
          "Content-Type": "application/json",
          "payload": s,
        }).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          globals.reloadData = true;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Coins were sent!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            elevation: 5.0,
          ));
        } else {
          Navigator.of(context).pop();
          Dialogs.openInsufficientBox(context);
        }
      }
    } on TimeoutException catch (_) {
      print("Timeout");
    } catch (e) {
      print(e);
    }
  }

  void displayErrDialog(context, title, text) => showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(title), content: Text(text)),
      );

  void _deleteContactPrompt(int id) async {
    Dialogs.openContactDeteleBox(context, id, _deleteContact);
  }

  void _deleteContact(int contactID) async {
    try {
      String? jwt = await storage.read(key: "jwt");
      String? id = await storage.read(key: globals.ID);

      List<Contact> details = await AppDatabase().getContact(contactID);
      String? addr = details[0].addr;
      String? name = details[0].name;

      Map<String, dynamic> m = {
        "Authorization": jwt,
        "id": id,
        "request": "deleteContact",
        "param1": name,
        "param2": addr,
      };

      var s = encryptAESCryptoJS(json.encode(m), "rp9ww*jK8KX_!537e%Crmf");

      final response = await http.get(Uri.parse(globals.SERVER_URL + '/data'), headers: {
        "Content-Type": "application/json",
        "payload": s,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        AppDatabase().deleteContact(contactID);
        setState(() {
          _getUserFuture = _getUsers();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Contact deleted"),
          backgroundColor: Color(0xFF63C9F3),
          behavior: SnackBarBehavior.fixed,
          elevation: 5.0,
        ));
      }
    } on TimeoutException catch (_) {
      print("Timeout");
    } catch (e) {
      print(e);
    }
  }

  _refreshContacts() async {
    setState(() {
      _getUserFuture = null;
      _getUserFuture = _getUsers();
    });
  }

  _searchUsers(String text) async {
    var d = AppDatabase().searchContact(text);
    setState(() {
      _getUserFuture = d;
    });
  }

  Future<List<Contact>> _getUsers() async {
    var res = await AppDatabase().getContacts();
    return List.generate(res.length, (i) {
      return Contact(
        id: res[i]['id'] as int,
        name: res[i]['name'] as String,
        addr: res[i]['addr'] as String,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(
          mainMenu: false,
          hasImage: true,
          image: "contactsicon.png",
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHeader(
                  title: AppLocalizations.of(context)!.contacts,
                  backArrow: true,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0, bottom: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                    color: Theme.of(context).konjHeaderColor,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Flexible(
                      child: FractionallySizedBox(
                        widthFactor: 0.95,
                        child: SizedBox(
                          height: 45,
                          child: TextField(
                            controller: _controller,
                            onChanged: (String text) async {
                              _searchUsers(text);
                            },
                            style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white70),
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.all(8.0),
                              filled: true,
                              hoverColor: Colors.white24,
                              focusColor: Colors.white24,
                              fillColor: Theme.of(context).konjTextFieldHeaderColor,
                              labelText: "",
                              labelStyle: Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white54, fontSize: 18.0),
                              hintText: AppLocalizations.of(context)!.search_contact,
                              hintStyle: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white54, fontSize: 18.0),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white70,
                              ),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30, width: 2.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10, width: 1.0), borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 15.0, top: 1.0),
                      child: RoundButton(
                          height: 40,
                          width: 40,
                          color: Theme.of(context).konjHeaderColor,
                          onTap: () {
                            Navigator.of(context)
                                .push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
                                  return const AddressAddScreen();
                                }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
                                  return FadeTransition(opacity: animation, child: child);
                                }))
                                .then((value) => _refreshContacts());
                          },
                          splashColor: Colors.black45,
                          icon: const Icon(
                            Icons.add,
                            size: 35,
                            color: Colors.white70,
                          )),
                    ),
                  ]),
                ),
                Expanded(
                  child: FutureBuilder(
                      future: _getUserFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var _data = snapshot.data as List<Contact>?;
                          return Padding(
                            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32.0), bottomRight: Radius.circular(32.0)),
                              child: Container(
                                padding: const EdgeInsets.only(left: 0.0, right: 0.0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _data!.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return ContactTile(
                                      key: Key(_data[index].addr!),
                                      contact: _data[index],
                                      func: _deleteContactPrompt,
                                      func2: _openSelectBox,
                                      func3: _openEditBox,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.all(10.0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: const <Widget>[
                              SizedBox(child: CircularProgressIndicator(), height: 50.0, width: 50.0),
                            ]),
                          );
                        }
                      }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void dialogDelete(context, int id) async {
    Widget remindButton = TextButton(
      child: Text(AppLocalizations.of(context)!.yes, style: const TextStyle(color: Colors.red)),
      onPressed: () {
        _deleteContact(id);
        Navigator.of(context).pop();
      },
    );
    Widget cancelButton = TextButton(
      child: Text(AppLocalizations.of(context)!.no),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.notice_warn),
      content: Text(AppLocalizations.of(context)!.contact_del),
      actions: [
        remindButton,
        cancelButton,
      ],
    );
    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.white;
  }
}
