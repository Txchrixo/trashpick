import 'package:get/get.dart';
import '../features/picker/controllers/picker_home_controller.dart';
import '../services/location_service.dart';

class PickerBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LocationService());
    Get.put(PickerHomeController());
  }
}
