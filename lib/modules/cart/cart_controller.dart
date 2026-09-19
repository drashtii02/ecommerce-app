import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/local_storage.dart';
import '../../core/constants/storage_keys.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';

class CartController extends GetxController {
  final LocalStorage _storage = Get.find<LocalStorage>();

  final cartItems = <int, CartItemModel>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCart();
  }

  int get totalItems =>
      cartItems.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      cartItems.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool isInCart(int productId) => cartItems.containsKey(productId);

  int getQuantity(int productId) =>
      cartItems[productId]?.quantity ?? 0;

  void addToCart(ProductModel product, {int quantity = 1}) {
    if (cartItems.containsKey(product.id)) {
      cartItems[product.id]!.quantity += quantity;
      cartItems.refresh();
    } else {
      cartItems[product.id] = CartItemModel(
        product: product,
        quantity: quantity,
      );
    }
    _saveCart();
    Get.snackbar(
      'Added to Cart',
      '${product.title} added to cart',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(8),
      icon: const Icon(Icons.shopping_cart, color: Colors.green),
    );
  }

  void removeFromCart(int productId) {
    final item = cartItems.remove(productId);
    if (item != null) {
      _saveCart();
      Get.snackbar(
        'Removed',
        '${item.product.title} removed from cart',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(8),
      );
    }
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    if (cartItems.containsKey(productId)) {
      cartItems[productId]!.quantity = quantity;
      cartItems.refresh();
      _saveCart();
    }
  }

  void incrementQuantity(int productId) {
    if (cartItems.containsKey(productId)) {
      cartItems[productId]!.quantity++;
      cartItems.refresh();
      _saveCart();
    }
  }

  void decrementQuantity(int productId) {
    if (cartItems.containsKey(productId)) {
      if (cartItems[productId]!.quantity <= 1) {
        removeFromCart(productId);
      } else {
        cartItems[productId]!.quantity--;
        cartItems.refresh();
        _saveCart();
      }
    }
  }

  void clearCart() {
    cartItems.clear();
    _saveCart();
  }

  void _saveCart() {
    final cartList = cartItems.values.map((e) => e.toJson()).toList();
    _storage.writeJson(StorageKeys.cartItems, cartList);
  }

  void _loadCart() {
    final data = _storage.readJson(StorageKeys.cartItems);
    if (data != null && data is List) {
      for (final itemJson in data) {
        final item = CartItemModel.fromJson(itemJson);
        cartItems[item.product.id] = item;
      }
    }
  }
}
