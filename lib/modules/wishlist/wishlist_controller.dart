import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class WishlistController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();

  final wishlistIds = <int>[].obs;
  final wishlistProducts = <ProductModel>[].obs;
  final isLoadingWishlist = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadWishlistIds();
  }

  void _loadWishlistIds() {
    wishlistIds.value = _productRepo.getWishlistIds();
  }

  bool isInWishlist(int productId) {
    return wishlistIds.contains(productId);
  }

  void toggleWishlist(int productId) {
    if (wishlistIds.contains(productId)) {
      wishlistIds.remove(productId);
      wishlistProducts.removeWhere((p) => p.id == productId);
      Get.snackbar(
        'Removed',
        'Product removed from wishlist',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(8),
      );
    } else {
      wishlistIds.add(productId);
      Get.snackbar(
        'Added',
        'Product added to wishlist',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(8),
      );
    }
    _productRepo.saveWishlistIds(wishlistIds.toList());
  }

  Future<void> loadWishlistProducts() async {
    isLoadingWishlist.value = true;
    wishlistProducts.clear();

    for (final id in wishlistIds) {
      try {
        final product = await _productRepo.getProductById(id);
        wishlistProducts.add(product);
      } catch (_) {
        // skip products that fail to load
      }
    }

    isLoadingWishlist.value = false;
  }
}
