import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dental_gate/core/app.dart';
import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/controllers/notifications_controller.dart';
import 'package:dental_gate/firebase_options.dart';
import 'package:dental_gate/services/fcm_foreground_notifications.dart';
import 'package:dental_gate/services/token_storage.dart';
import 'package:dental_gate/view/notifications/notifications_view.dart';

const Duration _fcmTokenTimeout = Duration(seconds: 12);
const Duration _pushRetryDelay = Duration(milliseconds: 300);
const int _maxPushOpenRetries = 10;
Map<String, dynamic>? _pendingPushTapData;
bool _pushOpenInProgress = false;
int _pushOpenRetryCount = 0;
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
  _pendingPushTapData = _normalizePushData(data);
  unawaited(_drainPushNavigationQueue());
}

Future<void> _openNotificationsFromPush() async {
  if (!Get.isRegistered<NotificationsController>()) {
    Get.put(NotificationsController(userId: ''), permanent: false);
  } else {
    unawaited(Get.find<NotificationsController>().loadNotifications());
  }
  await Get.to<void>(() => const NotificationsView());
}

Future<bool> _tryHandlePushTap(Map<String, dynamic> data) async {
  if (Get.key.currentState == null) return false;

  final hasSession = await TokenStorage.instance.readTokens() != null;
  if (!hasSession) {
    // لو المستخدم مسجل خروج، نتجاهل التنقل القادم من الإشعار.
    return true;
  }

  final route = data['route']?.toString().trim();
  if (route != null && route.isNotEmpty && route != Routes.splash) {
    if (Get.currentRoute != route) {
      await Get.toNamed<void>(route);
    }
    return true;
  }

  if (Get.currentRoute != Routes.main) {
    await Get.offAllNamed<void>(Routes.main);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  await _openNotificationsFromPush();
  return true;
}

Future<void> _drainPushNavigationQueue() async {
  if (_pushOpenInProgress) return;
  _pushOpenInProgress = true;
  try {
    while (_pendingPushTapData != null) {
      final data = _pendingPushTapData!;
      final handled = await _tryHandlePushTap(data);
      if (handled) {
        _pendingPushTapData = null;
        _pushOpenRetryCount = 0;
        continue;
      }
      _pushOpenRetryCount += 1;
      if (_pushOpenRetryCount >= _maxPushOpenRetries) {
        debugPrint('Push tap ignored: app was not ready in time');
        _pendingPushTapData = null;
        _pushOpenRetryCount = 0;
        break;
      }
      await Future<void>.delayed(_pushRetryDelay);
    }
  } finally {
    _pushOpenInProgress = false;
  }
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
    FcmForegroundNotifications.onNotificationTap = _queuePushNavigation;
    FcmForegroundNotifications.attachForegroundListener();

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _queuePushNavigation(message.data);
    });
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _queuePushNavigation(initialMessage.data);
    }
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
