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
import 'package:dental_gate/services/push_tap_router.dart';

const Duration _fcmTokenTimeout = Duration(seconds: 12);
const Duration _permissionTimeout = Duration(seconds: 6);

Future<void> _requestNotificationPermissionSafely(
  FirebaseMessaging messaging,
) async {
  try {
    await messaging
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
        )
        .timeout(_permissionTimeout);
  } on TimeoutException {
    debugPrint('requestPermission timeout: سيكمل التطبيق بدون انتظار.');
  } catch (e, st) {
    debugPrint('requestPermission failed: $e\n$st');
  }
}

Future<void> _readInitialPushMessage(FirebaseMessaging messaging) async {
  try {
    final initialMessage = await messaging.getInitialMessage().timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
    if (initialMessage != null) {
      PushTapRouter.setPending(initialMessage.data);
      unawaited(PushTapRouter.handleIfReady());
    }
  } catch (e, st) {
    debugPrint('getInitialMessage failed: $e\n$st');
  }
}
/////
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isCurrentPlatformConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Map<String, dynamic> _normalizePushData(Map<String, dynamic> raw) {
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

void _queuePushNavigation(Map<String, dynamic> data) {
  if (data.isEmpty) return;
  PushTapRouter.setPending(_normalizePushData(data));
  unawaited(PushTapRouter.handleIfReady());
}

Future<void> _logFcmToken() async {
  if (Firebase.apps.isEmpty) return;
  try {
    final messaging = FirebaseMessaging.instance;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _requestNotificationPermissionSafely(messaging);
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _requestNotificationPermissionSafely(messaging);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // تجنب تجميد البداية: طلب إذن الإشعارات على أندرويد يتم بالخلفية.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 900), () async {
          await _requestNotificationPermissionSafely(messaging);
        }),
      );
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FcmForegroundNotifications.init().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint('FcmForegroundNotifications.init timeout');
      },
    );
    FcmForegroundNotifications.onNotificationTap = _queuePushNavigation;
    FcmForegroundNotifications.attachForegroundListener();

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _queuePushNavigation(message.data);
    });
    unawaited(_readInitialPushMessage(messaging));
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
