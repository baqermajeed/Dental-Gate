import 'package:get/get.dart';

import 'package:dental_gate/controllers/professional_profile_controller.dart';

class ProfessionalProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfessionalProfileController());
  }
}
