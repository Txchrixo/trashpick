import 'package:get/get.dart';
import '../features/client/controllers/client_home_controller.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

class ClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LocationService());
    Get.put(StorageService());
    Get.put(ClientHomeController());
  }
}
