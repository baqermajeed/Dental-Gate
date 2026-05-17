import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/bookmarks_controller.dart';
import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/controllers/talabat_controller.dart';
import 'package:dental_gate/services/job_search_history_service.dart';
import 'package:dental_gate/services/token_storage.dart';

/// بعد تأكيد الحذف من الخادم: إزالة كل أثر للحساب محلياً (توكن، كاش، Hive، صور).
abstract final class AccountDeleteCleanup {
  static Future<void> runPostDeletionSweep() async {
    await TokenStorage.instance.clear();
    await JobSearchHistoryService.clearAll();

    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    PaintingBinding.instance.imageCache.clear();

    try {
      await Get.find<BookmarksController>().clearPersistedCacheForAccountRemoval();
    } catch (_) {}

    try {
      Get.find<HomeController>().clearSessionStateAfterLogout();
    } catch (_) {}

    try {
      Get.find<TalabatController>().clearSessionStateAfterLogout();
    } catch (_) {}
  }
}
