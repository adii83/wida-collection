import 'package:get/get.dart';
import '../controllers/network_location_controller.dart';
import '../services/location_service.dart';

/// Binding untuk Network Location Module
class NetworkLocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
    Get.lazyPut<NetworkLocationController>(
      () => NetworkLocationController(),
      fenix: true,
    );
  }
}
