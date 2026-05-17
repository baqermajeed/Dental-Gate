import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

import 'package:dental_gate/models/app_notification.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/services/fcm_registration_service.dart';
import 'package:dental_gate/view/jobs/job_detail_view.dart';

enum NotificationFilterTab {
  all,
  jobPostingApplications,
  myApplicationStatuses,
  appAnnouncements,
}

class NotificationsController extends GetxController {
  NotificationsController({required this.userId});

  final String userId;

  final selectedTab = NotificationFilterTab.all.obs;
  final items = <AppNotificationItem>[].obs;
  final streamError = Rxn<String>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(FcmRegistrationService.instance.syncToBackend());
    unawaited(loadNotifications());
  }

  /// تحميل كل الإشعارات من الباكند ثم التصفية محلياً حسب التبويب.
  Future<void> loadNotifications() async {
    isLoading.value = true;
    streamError.value = null;
    try {
      final list = await ApiService.instance.fetchNotifications(
        category: 'all',
        limit: 200,
      );
      items.assignAll(list);
    } on ApiException catch (e) {
      streamError.value = e.message;
      items.clear();
    } catch (e, st) {
      debugPrint('loadNotifications: $e\n$st');
      streamError.value = 'تعذر تحميل الإشعارات';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void setTab(NotificationFilterTab tab) {
    selectedTab.value = tab;
  }

  List<AppNotificationItem> get filteredItems {
    selectedTab.value;
    final all = List<AppNotificationItem>.from(items);
    switch (selectedTab.value) {
      case NotificationFilterTab.all:
        return all;
      case NotificationFilterTab.jobPostingApplications:
        return all
            .where((e) => e.type == AppNotificationType.jobPostingApplication)
            .toList(growable: false);
      case NotificationFilterTab.myApplicationStatuses:
        return all
            .where((e) => e.type == AppNotificationType.myApplicationStatus)
            .toList(growable: false);
      case NotificationFilterTab.appAnnouncements:
        return all
            .where((e) => e.type == AppNotificationType.appAnnouncement)
            .toList(growable: false);
    }
  }

  Future<void> onTileTap(AppNotificationItem n) async {
    if (!n.read) {
      try {
        final updated = await ApiService.instance.markNotificationRead(n.id);
        final i = items.indexWhere((e) => e.id == n.id);
        if (i >= 0) {
          items[i] = updated;
          items.refresh();
        }
      } on ApiException catch (e) {
        debugPrint('markNotificationRead: ${e.message}');
      } catch (e, st) {
        debugPrint('markNotificationRead: $e\n$st');
      }
    }

    final isJobNotification =
        n.type == AppNotificationType.jobPostingApplication ||
        n.type == AppNotificationType.myApplicationStatus;
    if (!isJobNotification) return;
    final jobId = n.jobId?.trim();
    if (jobId == null || jobId.isEmpty) return;

    try {
      final job = await ApiService.instance.fetchJobById(jobId);
      await Get.to(() => JobDetailView(job: job));
    } on ApiException catch (e) {
      Get.snackbar(
        'تعذر فتح الوظيفة',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('openJobFromNotification: $e\n$st');
      Get.snackbar(
        'تعذر فتح الوظيفة',
        'حدث خطأ غير متوقع',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
