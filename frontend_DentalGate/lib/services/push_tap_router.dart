import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';

/// إدارة ضغطة الإشعار بدون حلقات أو تنقلات متزامنة مع بداية التطبيق.
class PushTapRouter {
  PushTapRouter._();

  static Map<String, dynamic>? _pendingData;

  static void setPending(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    _pendingData = data.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<void> handleIfReady() async {
    final data = _pendingData;
    if (data == null) return;
    if (Get.key.currentState == null) return;
    if (Get.currentRoute == Routes.splash) return;

    _pendingData = null;
    final route = data['route']?.toString().trim();
    if (route != null && route.isNotEmpty && route != Routes.splash) {
      try {
        await Get.toNamed<void>(route);
        return;
      } catch (e, st) {
        debugPrint('PushTapRouter route error: $e\n$st');
      }
    }

    // إشعار عام: يكفي فتح التطبيق على الرئيسية.
    if (Get.currentRoute != Routes.main) {
      await Get.offAllNamed<void>(Routes.main);
    }
  }
}
