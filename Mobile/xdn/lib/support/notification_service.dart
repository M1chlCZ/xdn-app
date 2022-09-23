import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  //NotificationService a singleton object
  static final NotificationService _notificationService =
  NotificationService._internal();


  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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

      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannel(channel);

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

      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannel(channel2);
    }
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_notification');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,  onDidReceiveNotificationResponse: _onDidReceiveLocalNotificationResponse);
  }

  // void _registerNotification() async {
  //   _messaging = FirebaseMessaging.instance;
  //
  //   _messaging = FirebaseMessaging.instance;
  //   _messaging.getToken().then((value) {
  //     NetInterface.registerFirebaseToken(value!);
  //     // print(value + " / " + value.length.toString());
  //   });
  //
  //   NotificationSettings settings = await _messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     provisional: false,
  //     sound: true,
  //   );
  //
  //   _messaging.onTokenRefresh.listen((token) {
  //     NetInterface.registerFirebaseToken(token);
  //   });
  //
  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //       // print(message.data.toString());
  //       // print(message.notification.title.toString());
  //       // _setBadge();
  //       if (message.data.containsKey("transaction")) {
  //         Vibration.vibrate(duration: 50);
  //         print("refresh balance");
  //         if (_walletScreenKey.currentWidget != null) {
  //           _walletScreenKey.currentState!.notif();
  //         }
  //
  //         if (_stakingScreenKey.currentWidget != null) {
  //           _stakingScreenKey.currentState!.not();
  //         }
  //       }
  //
  //       if (message.data.containsKey("incomingMessage")) {
  //         Vibration.vibrate(duration: 50);
  //         print("new message");
  //         _getMessages();
  //         if (_messageScreenKey.currentWidget != null) {
  //           _messageScreenKey.currentState!.notReceived();
  //         }
  //       }
  //
  //       if (message.data.containsKey("outMessage")) {
  //         print("sent message");
  //         if (_messageScreenKey.currentWidget != null) {
  //           _messageScreenKey.currentState!.notReceived();
  //         }
  //       }
  //     });
  //   }
  // }

  Future _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    // _refreshBalance();
    // _setBadge();
    // _imagesave = false;
  }

  Future _onSelectNotification(String? payload) async {
    print(payload);
    // _refreshBalance();
  }

  void _onDidReceiveLocalNotificationResponse(NotificationResponse details) {
    print(details);
    // _refreshBalance();
  }
}