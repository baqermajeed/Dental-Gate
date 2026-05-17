import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/main_shell_controller.dart';
import 'package:dental_gate/view/home/home_view.dart';
import 'package:dental_gate/view/shell/tab_placeholders.dart';
import 'package:dental_gate/widgets/pill_bottom_nav_bar.dart';

/// الغلاف الرئيسي بعد تسجيل الدخول: تبويبات + شريط تنقل سفلي (pill).
class MainShell extends GetView<MainShellController> {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(
        () => Scaffold(
          backgroundColor: kShellBackgroundColor,
          body: IndexedStack(
            clipBehavior: Clip.none,
            index: controller.currentIndex.value,
            children: const [
              HomeView(),
              OrdersTabPage(),
              BookmarksTabPage(),
              SettingsTabPage(),
            ],
          ),
          bottomNavigationBar: PillBottomNavBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.setIndex,
          ),
        ),
      ),
    );
  }
}
