import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class ProductRepository {
  final ProductProvider _provider;
  final LocalStorage _storage;

  ProductRepository(this._provider, this._storage);

  /// Cache-first: returns cached data if available, null if not.
  ProductResponse? getCachedProductsSync() {
    return _getCachedProducts();
  }

  /// Returns true if cache exists
  bool hasCachedProducts() {
    return _getCachedProducts() != null;
  }

  /// Get all cached products as flat list (for offline search)
  List<ProductModel> getAllCachedProducts() {
    final cached = _getCachedProducts();
    if (cached == null) return [];
    return cached.products;
  }

  Future<ProductResponse> getProducts({int skip = 0, int limit = 20}) async {
    // Always attempt the API call — don't rely solely on connectivity check
    try {
      final data = await _provider.getProducts(skip: skip, limit: limit);
      if (skip == 0) {
        _cacheProducts(data);
      } else {
        _appendCachedProducts(data);
      }
      return ProductResponse.fromJson(data);
    } on DioException catch (e) {
      if (skip == 0) {
        final cached = _getCachedProducts();
        if (cached != null) return cached;
      }
      throw _handleDioError(e);
    }
  }

  Future<ProductResponse> searchProducts({
    required String query,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final data =
          await _provider.searchProducts(query: query, skip: skip, limit: limit);
      return ProductResponse.fromJson(data);
    } on DioException catch (e) {
      // Fallback to offline search on network error
      final offlineResult = _offlineSearch(query, skip, limit);
      if (offlineResult.products.isNotEmpty) return offlineResult;
      throw _handleDioError(e);
    }
  }

  ProductResponse _offlineSearch(String query, int skip, int limit) {
    final allProducts = getAllCachedProducts();
    final q = query.toLowerCase();
    final filtered = allProducts.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          (p.brand?.toLowerCase().contains(q) ?? false) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    final total = filtered.length;
    final paged = filtered.skip(skip).take(limit).toList();
    return ProductResponse(
      products: paged,
      total: total,
      skip: skip,
      limit: limit,
    );
  }

  Future<ProductModel> getProductById(int id) async {
    try {
      final data = await _provider.getProductById(id);
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      // Fallback to cache on network error
      final cached = _getCachedProducts();
      if (cached != null) {
        final product = cached.products.where((p) => p.id == id).toList();
        if (product.isNotEmpty) return product.first;
      }
      throw _handleDioError(e);
    }
  }

  // Wishlist
  List<int> getWishlistIds() {
    final raw = _storage.read<String>(StorageKeys.wishlistIds);
    if (raw == null) return [];
    return List<int>.from(json.decode(raw));
  }

  Future<void> saveWishlistIds(List<int> ids) async {
    await _storage.write(StorageKeys.wishlistIds, json.encode(ids));
  }

  // Cache helpers
  void _cacheProducts(Map<String, dynamic> data) {
    _storage.writeJson(StorageKeys.cachedProducts, data);
    _storage.write(
        StorageKeys.cachedProductsTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  void _appendCachedProducts(Map<String, dynamic> newData) {
    final cached = _storage.readJson(StorageKeys.cachedProducts);
    if (cached != null) {
      final existingProducts = List<Map<String, dynamic>>.from(
          (cached['products'] as List?) ?? []);
      final newProducts = List<Map<String, dynamic>>.from(
          (newData['products'] as List?) ?? []);
      final existingIds = existingProducts.map((p) => p['id']).toSet();
      for (final p in newProducts) {
        if (!existingIds.contains(p['id'])) {
          existingProducts.add(p);
        }
      }
      final merged = {
        'products': existingProducts,
        'total': newData['total'] ?? cached['total'] ?? 0,
        'skip': 0,
        'limit': existingProducts.length,
      };
      _storage.writeJson(StorageKeys.cachedProducts, merged);
    }
  }

  ProductResponse? _getCachedProducts() {
    final cached = _storage.readJson(StorageKeys.cachedProducts);
    if (cached != null) {
      return ProductResponse.fromJson(Map<String, dynamic>.from(cached));
    }
    return null;
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      default:
        return Exception('Something went wrong. Please try again.');
    }
  }
}
