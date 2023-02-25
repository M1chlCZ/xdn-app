import 'dart:async';
import 'dart:io';

import 'package:digitalnote/net_interface/interface.dart';
import 'package:digitalnote/support/NetInterface.dart';
import 'package:digitalnote/support/Utils.dart';
import 'package:digitalnote/support/secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message);
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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  setNotifications() async {
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    if (Platform.isAndroid) {
      AndroidNotificationChannel channel = const AndroidNotificationChannel(
        'xdn1', // id
        'Send/Receive notifications', // title
        description: 'This channel is used for transaction notifications.',
        // description
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.white,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
          .createNotificationChannel(channel);

      AndroidNotificationChannel channel2 = const AndroidNotificationChannel(
        'xdn2', // id
        'Message notifications', // title
        description: 'This channel is used for message notifications.',
        // description
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.white,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
          .createNotificationChannel(channel2);
    }
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_notification');
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: (payload) {
      print(payload.toString());
    });
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(
          (message) async {
        if (message.notification?.title != null) {
          flutterLocalNotificationsPlugin.show(
            message.hashCode,
            message.notification!.title,
            message.notification!.body,
            const NotificationDetails(
                android: AndroidNotificationDetails("xdn1", "XDN Deposit/Withdrawal Info",
                    importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true, icon: "@drawable/ic_notification"),
                iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, sound: "default")),
            payload: message.data["func"],
          );
        }

        if (message.data.containsKey('data')) {
          streamCtlr.sink.add(message.data['data']);
        }
        if (message.data.containsKey('notification')) {
          streamCtlr.sink.add(message.data['notification']);
        }
        titleCtlr.sink.add(message.notification!.title!);
        bodyCtlr.sink.add(message.notification!.body!);
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.data.keys.first == 'link') {
        Utils.openLink(message.data["dataLink"]);
      }
    });
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      _tokenUpload(token);
      SecureStorage.write(key: 'firebase_token', value: token);
    }
  }

  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    // Dialogs.openAlertBox(context, "Alert", payload!);
  }

  onNotificationRegister() {
    FirebaseMessaging.onMessage.listen(
          (message) async {
        if (message.data.containsKey('data')) {
          streamCtlr.sink.add(message.data['data']);
        }
        if (message.data.containsKey('notification')) {
          streamCtlr.sink.add(message.data['notification']);
        }
        titleCtlr.sink.add(message.notification!.title!);
        bodyCtlr.sink.add(message.notification!.body!);
      },
    );
  }

  void _tokenUpload(String? token) async{
    try {
      await NetInterface.registerFirebaseToken(token);
    } catch (e) {
      print(e);
    }
  }

  dispose() {
    streamCtlr.close();
    bodyCtlr.close();
    titleCtlr.close();
  }
}
