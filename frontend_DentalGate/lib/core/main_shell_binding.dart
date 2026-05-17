import 'package:get/get.dart';

import 'package:dental_gate/controllers/bookmarks_controller.dart';
import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/controllers/main_shell_controller.dart';
import 'package:dental_gate/controllers/settings_controller.dart';
import 'package:dental_gate/controllers/talabat_controller.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MainShellController(), permanent: false);
    Get.put(HomeController(), permanent: false);
    Get.put(BookmarksController(), permanent: true);
    Get.put(TalabatController(), permanent: false);
    Get.put(SettingsController(), permanent: false);
  }
}
