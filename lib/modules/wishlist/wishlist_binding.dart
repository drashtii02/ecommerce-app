import 'package:get/get.dart';
import 'wishlist_controller.dart';

class WishlistBinding extends Bindings {
  @override
  void dependencies() {
    // WishlistController is already initialized globally, no need to re-init
    if (!Get.isRegistered<WishlistController>()) {
      Get.lazyPut<WishlistController>(() => WishlistController());
    }
  }
}
