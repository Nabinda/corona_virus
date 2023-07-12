import 'dart:developer';

import 'package:corona_virus/app.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background Notification: $message");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent // transparent status bar
      ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final firebaseMessaging = FirebaseMessaging.instance;
  await firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  await firebaseMessaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  try {
    await FirebaseAnalytics.instance
        .logAppOpen()
        .then((value) => log('APP OPEN LOGGED'));
  } catch (e) {
    log('App Open Log Error: $e');
  }
  final fcmToken = await FirebaseMessaging.instance.getToken();
  log('FCMTOKEN :$fcmToken');
  runApp(const App());
}
