import 'dart:async';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data.containsKey('data')) {
    final data = message.data['data'];
  }

  if (message.data.containsKey('notification')) {
    final notification = message.data['notification'];
  }
  // Or do other work.
}

class FCM {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final ComInterface _interface = ComInterface();
  final streamCtlr = StreamController<String>.broadcast();
  final titleCtlr = StreamController<String>.broadcast();
  final bodyCtlr = StreamController<String>.broadcast();

  setNotifications() {
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    _firebaseMessaging.getToken().then((value) => _tokenUpload(value));
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(
      (message) async {

        // print(message.data.toString());
        // print(message.notification!.title.toString());
        bodyCtlr.sink.add(message.toString());
        // if (message.data.containsKey('outMessage')) {
        //   bodyCtlr.sink.add(message.data['outMessage']);
        // }
        // if (message.data.containsKey('data')) {
        //   streamCtlr.sink.add(message.data['data']);
        // }
        // if (message.data.containsKey('notification')) {
        //   streamCtlr.sink.add(message.data['notification']);
        // }
        // if (message.notification?.title != null) {
        //   titleCtlr.sink.add(message.notification!.title!);
        // }
        // if (message.notification?.body != null) {
        //   bodyCtlr.sink.add(message.notification!.body!);
        // }
        //
        // if (message.data.containsKey("incomingMessage")) {
        //   // Vibration.vibrate(duration: 50);
        //   print("new message");
        //   // _getMessages();
        //   bodyCtlr.sink.add("new message");
        //   // if (_messageScreenKey.currentWidget != null) {
        //   //   _messageScreenKey.currentState!.notReceived();
        //   // }
        // }
        //
        // if (message.data.containsKey("outMessage")) {
        //   print("sent message");
        //   bodyCtlr.sink.add("new message");
        //   // if (_messageScreenKey.currentWidget != null) {
        //   //   _messageScreenKey.currentState!.notReceived();
        //   // }
        // }
      },
    );

  }

  // onNotificationRegister() {
  //   FirebaseMessaging.onMessage.listen(
  //         (message) async {
  //       if (message.data.containsKey('data')) {
  //         streamCtlr.sink.add(message.data['data']);
  //       }
  //       if (message.data.containsKey('notification')) {
  //         streamCtlr.sink.add(message.data['notification']);
  //       }
  //
  //       titleCtlr.sink.add(message.notification!.title!);
  //       bodyCtlr.sink.add(message.notification!.body!);
  //     },
  //   );
  // }

  void _tokenUpload(String? token) {
    // Map <String, dynamic> req = {
    //   "token" : token,
    // };
    print(token!);
    NetInterface.registerFirebaseToken(token);
    // _interface.post('Security/UpdateFirebaseToken', req);
  }

  dispose() {
    streamCtlr.close();
    bodyCtlr.close();
    titleCtlr.close();
  }
}
