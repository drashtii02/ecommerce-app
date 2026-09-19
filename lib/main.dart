import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/network/api_client.dart';
import 'core/network/connectivity_service.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/providers/product_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'modules/cart/cart_controller.dart';
import 'modules/wishlist/wishlist_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  _initDependencies();
  runApp(const MyApp());
}

void _initDependencies() {
  final storage = LocalStorage();
  final apiClient = ApiClient();
  final connectivity = ConnectivityService();

  Get.put(storage);
  Get.put(apiClient);
  Get.put(connectivity);
  Get.put(AuthRepository(storage));
  Get.put(ProductProvider(apiClient));
  Get.put(ProductRepository(
    Get.find<ProductProvider>(),
    storage,
  ));
  Get.put(ThemeController());
  Get.put(WishlistController());
  Get.put(CartController());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final authRepo = Get.find<AuthRepository>();

    return Obx(
      () => GetMaterialApp(
        title: 'ShopEase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeCtrl.themeMode,
        initialRoute:
            authRepo.isLoggedIn() ? AppRoutes.home : AppRoutes.login,
        getPages: AppPages.pages,
        defaultTransition: Transition.cupertino,
      ),
    );
  }
}
