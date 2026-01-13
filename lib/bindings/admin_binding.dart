import 'package:get/get.dart';
import '../features/admin/controllers/admin_home_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminHomeController(), permanent: false);
  }
}
