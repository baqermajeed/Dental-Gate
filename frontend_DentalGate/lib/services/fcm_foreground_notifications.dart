import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// يعرض إشعاراً نظامياً على أندرويد عند وصول رسالة FCM والتطبيق في المقدمة.
class FcmForegroundNotifications {
  FcmForegroundNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'dental_gate_push';
  static const _channelName = 'Dental Gate';
  static bool _initialized = false;
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  static Future<void> init() async {
    if (_initialized) return;
    if (defaultTargetPlatform != TargetPlatform.android) {
      _initialized = true;
      return;
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final parsed = jsonDecode(payload);
          if (parsed is Map<String, dynamic>) {
            onNotificationTap?.call(parsed);
            return;
          }
          if (parsed is Map) {
            onNotificationTap?.call(
              parsed.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            );
          }
        } catch (e, st) {
          debugPrint('FcmForegroundNotifications.tap: $e\n$st');
        }
      },
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'إشعارات من Firebase والخادم',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_initialized) await init();

    final n = message.notification;
    final data = message.data;
    final title = n?.title ??
        data['title']?.toString() ??
        'Dental Gate';
    final body = n?.body ??
        data['body']?.toString() ??
        '';

    if (body.isEmpty && title == 'Dental Gate') {
      return;
    }

    final id = (message.messageId ??
            '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}')
        .hashCode
        .abs()
        .remainder(2147483647);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'إشعارات من Firebase والخادم',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body.isEmpty ? ' ' : body,
        notificationDetails: details,
        payload: data.isNotEmpty ? jsonEncode(data) : null,
      );
    } catch (e, st) {
      debugPrint('FcmForegroundNotifications.show: $e\n$st');
    }
  }

  static void attachForegroundListener() {
    FirebaseMessaging.onMessage.listen(showFromRemoteMessage);
  }
}
