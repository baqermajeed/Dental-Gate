import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'package:dental_gate/services/api_service.dart' show ApiException, ApiService;
import 'package:dental_gate/services/token_storage.dart';

/// طلب صلاحيات FCM، جلب التوكن، وإرساله للباكند (بدون Firestore).
class FcmRegistrationService {
  FcmRegistrationService._();

  static final FcmRegistrationService instance = FcmRegistrationService._();

  bool _listeningRefresh = false;

  Future<void> syncToBackend() async {
    if (Firebase.apps.isEmpty) {
      // قد يُستدعى هذا مباشرة بعد تسجيل الدخول قبل اكتمال initFirebase.
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (Firebase.apps.isNotEmpty) break;
      }
      if (Firebase.apps.isEmpty) {
        debugPrint('FcmRegistrationService: Firebase غير مهيأ بعد');
        return;
      }
    }
    try {
      final messaging = FirebaseMessaging.instance;
      if (!kIsWeb) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      final access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        return;
      }

      try {
        await ApiService.instance.registerFcmToken(token);
      } on ApiException catch (e) {
        debugPrint('registerFcmToken: ${e.message}');
      }

      if (!_listeningRefresh) {
        _listeningRefresh = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          final a = await TokenStorage.instance.accessToken();
          if (a == null || a.isEmpty || newToken.isEmpty) return;
          try {
            await ApiService.instance.registerFcmToken(newToken);
          } on ApiException catch (e) {
            debugPrint('onTokenRefresh registerFcmToken: ${e.message}');
          } catch (e, st) {
            debugPrint('onTokenRefresh: $e\n$st');
          }
        });
      }
    } catch (e, st) {
      debugPrint('FcmRegistrationService.syncToBackend: $e\n$st');
    }
  }
}
