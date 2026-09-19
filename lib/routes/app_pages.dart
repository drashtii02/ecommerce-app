import 'package:get/get.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_screen.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_screen.dart';
import '../modules/product_detail/product_detail_binding.dart';
import '../modules/product_detail/product_detail_screen.dart';
import '../modules/wishlist/wishlist_binding.dart';
import '../modules/wishlist/wishlist_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.productDetail,
      page: () => const ProductDetailScreen(),
      binding: ProductDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.wishlist,
      page: () => const WishlistScreen(),
      binding: WishlistBinding(),
    ),
  ];
}
