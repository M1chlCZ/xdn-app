// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA10mG00oXArmnan198ogJqvTbvUWDpRCw',
    appId: '1:121483500104:android:a2f600d6ef9aa78ea4167d',
    messagingSenderId: '121483500104',
    projectId: 'xdn-project',
    storageBucket: 'xdn-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6jY6cEvTejx5ZLYeSS4CctfxCMhsh1pQ',
    appId: '1:121483500104:ios:abf5bab46011270ba4167d',
    messagingSenderId: '121483500104',
    projectId: 'xdn-project',
    storageBucket: 'xdn-project.appspot.com',
    androidClientId: '121483500104-idfnmjr3l0mkmmue5vkppl30oif9ovrr.apps.googleusercontent.com',
    iosClientId: '121483500104-q7f9gd5absk730vqbn400mbq8koqjojd.apps.googleusercontent.com',
    iosBundleId: 'com.m1chl.xdn',
  );
}
