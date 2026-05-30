import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dental_gate/core/app.dart';
import 'package:dental_gate/firebase_options.dart';
import 'package:dental_gate/services/fcm_foreground_notifications.dart';

const Duration _fcmTokenTimeout = Duration(seconds: 12);
/////
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isCurrentPlatformConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> _logFcmToken() async {
  if (Firebase.apps.isEmpty) return;
  try {
    final messaging = FirebaseMessaging.instance;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await messaging.requestPermission();
    }
    final token = await messaging.getToken().timeout(
      _fcmTokenTimeout,
      onTimeout: () {
        debugPrint(
          'FCM getToken: انتهت المهلة (محاكي بدون Google Play؟) — التطبيق يعمل بدون توكن.',
        );
        return null;
      },
    );
    if (token != null) {
      // ignore: avoid_print
      print('🔥 FCM TOKEN: $token');
    }
  } catch (e, st) {
    debugPrint('getFCMToken: $e\n$st');
  }
}

Future<void> _initFirebase() async {
  if (!DefaultFirebaseOptions.isCurrentPlatformConfigured) {
    debugPrint(
      'Firebase: تخطي التهيئة — أضف تطبيق iOS في مشروع dental-gate-notif '
      'ثم شغّل: dart pub global activate flutterfire_cli && flutterfire configure',
    );
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final messaging = FirebaseMessaging.instance;
    if (!kIsWeb) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FcmForegroundNotifications.init();
    FcmForegroundNotifications.attachForegroundListener();
    unawaited(_logFcmToken());
  } catch (e, st) {
    debugPrint('Firebase init skipped (استبدل firebase_options.dart): $e\n$st');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const DentalGateApp());
  // لا نحجب أول شاشة: تهيئة Firebase تعمل بالخلفية.
  unawaited(_initFirebase());
}
