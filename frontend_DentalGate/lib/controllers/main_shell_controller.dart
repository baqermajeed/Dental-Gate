import 'dart:async';

import 'package:get/get.dart';

import 'package:dental_gate/controllers/talabat_controller.dart';

/// فهرس التبويب السفلي في [MainShell].
class MainShellController extends GetxController {
  final currentIndex = 0.obs;

  void setIndex(int i) {
    if (i == currentIndex.value) {
      // Allow manual refresh when user taps "Talabat" tab again.
      if (i == 1 && Get.isRegistered<TalabatController>()) {
        unawaited(Get.find<TalabatController>().load());
      }
      return;
    }
    currentIndex.value = i;
    if (i == 1 && Get.isRegistered<TalabatController>()) {
      unawaited(Get.find<TalabatController>().load());
    }
  }
}
