import 'package:get/get.dart';

/// حالة واجهة صفحة الإعدادات (مثل تفعيل الإشعارات).
class SettingsController extends GetxController {
  final notificationsEnabled = true.obs;

  void setNotifications(bool value) => notificationsEnabled.value = value;
}
