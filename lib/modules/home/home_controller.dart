import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/connectivity_service.dart';

class HomeController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  final products = <ProductModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final hasMoreData = true.obs;
  final isRefreshingInBackground = false.obs;
  final isOffline = false.obs;
  final showFromCache = false.obs;

  // Search
  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  // Categories extracted from cached products
  final categories = <String>[].obs;
  final selectedCategory = ''.obs;

  // View mode
  final isGridView = true.obs;

  int _currentSkip = 0;
  int _totalProducts = 0;

  final scrollController = ScrollController();
  StreamSubscription? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    _loadCacheFirst();
    scrollController.addListener(_onScroll);
    _listenConnectivity();
  }

  void _listenConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      final offline = result.contains(ConnectivityResult.none);
      isOffline.value = offline;
      if (!offline) {
        if (hasError.value) {
          // Back online & error was showing — full retry
          fetchProducts();
        } else if (showFromCache.value) {
          // Back online & showing cached data — refresh in background
          _backgroundRefresh();
        }
      }
    });
    // Check initial state
    _connectivity.hasConnection().then((connected) {
      isOffline.value = !connected;
    });
  }

  /// Cache-first loading: show cached data instantly, then fetch fresh data in background
  Future<void> _loadCacheFirst() async {
    isLoading.value = true;
    hasError.value = false;

    // Step 1: Try to show cached data immediately
    final cached = _productRepo.getCachedProductsSync();
    if (cached != null && cached.products.isNotEmpty) {
      products.value = cached.products;
      _totalProducts = cached.total;
      _currentSkip = cached.products.length;
      hasMoreData.value = _currentSkip < _totalProducts;
      _extractCategories(cached.products);
      showFromCache.value = true;
      isLoading.value = false;

      // Step 2: Refresh from API in background
      _backgroundRefresh();
    } else {
      // No cache — full network load
      await _networkFetch();
    }
  }

  Future<void> _backgroundRefresh() async {
    if (isRefreshingInBackground.value) return;
    isRefreshingInBackground.value = true;

    try {
      final response = await _productRepo.getProducts(
        skip: 0,
        limit: ApiEndpoints.pageLimit,
      );
      products.value = response.products;
      _totalProducts = response.total;
      _currentSkip = response.products.length;
      hasMoreData.value = _currentSkip < _totalProducts;
      _extractCategories(response.products);
      showFromCache.value = false;
    } catch (_) {
      // Background refresh failed silently — cached data still showing
    } finally {
      isRefreshingInBackground.value = false;
    }
  }

  Future<void> _networkFetch() async {
    isLoading.value = true;
    hasError.value = false;
    _currentSkip = 0;

    try {
      final response = await _productRepo.getProducts(
        skip: 0,
        limit: ApiEndpoints.pageLimit,
      );
      products.value = response.products;
      _totalProducts = response.total;
      _currentSkip = response.products.length;
      hasMoreData.value = _currentSkip < _totalProducts;
      _extractCategories(response.products);
      showFromCache.value = false;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void _extractCategories(List<ProductModel> items) {
    final cats = <String>{};
    for (final p in items) {
      if (p.category.isNotEmpty) cats.add(p.category);
    }
    // Also check all cached products for more categories
    final allCached = _productRepo.getAllCachedProducts();
    for (final p in allCached) {
      if (p.category.isNotEmpty) cats.add(p.category);
    }
    final sorted = cats.toList()..sort();
    categories.value = sorted;
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMoreProducts();
    }
  }

  Future<void> fetchProducts() async {
    await _networkFetch();
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    isLoadingMore.value = true;
    try {
      ProductResponse response;
      if (searchQuery.value.isNotEmpty) {
        response = await _productRepo.searchProducts(
          query: searchQuery.value,
          skip: _currentSkip,
          limit: ApiEndpoints.pageLimit,
        );
      } else {
        response = await _productRepo.getProducts(
          skip: _currentSkip,
          limit: ApiEndpoints.pageLimit,
        );
      }
      products.addAll(response.products);
      _currentSkip += response.products.length;
      hasMoreData.value = _currentSkip < response.total;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load more products',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshProducts() async {
    if (searchQuery.value.isNotEmpty) {
      await searchProducts(searchQuery.value);
    } else if (selectedCategory.value.isNotEmpty) {
      await filterByCategory(selectedCategory.value);
    } else {
      _currentSkip = 0;
      hasError.value = false;
      try {
        final response = await _productRepo.getProducts(
          skip: 0,
          limit: ApiEndpoints.pageLimit,
        );
        products.value = response.products;
        _totalProducts = response.total;
        _currentSkip = response.products.length;
        hasMoreData.value = _currentSkip < _totalProducts;
        showFromCache.value = false;
      } catch (e) {
        hasError.value = true;
        errorMessage.value = e.toString().replaceAll('Exception: ', '');
      }
    }
  }

  Future<void> searchProducts(String query) async {
    searchQuery.value = query;
    selectedCategory.value = '';

    if (query.isEmpty) {
      _loadCacheFirst();
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    _currentSkip = 0;

    try {
      final response = await _productRepo.searchProducts(
        query: query,
        skip: 0,
        limit: ApiEndpoints.pageLimit,
      );
      products.value = response.products;
      _totalProducts = response.total;
      _currentSkip = response.products.length;
      hasMoreData.value = _currentSkip < _totalProducts;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filterByCategory(String category) async {
    if (selectedCategory.value == category) {
      // Deselect
      selectedCategory.value = '';
      searchQuery.value = '';
      _loadCacheFirst();
      return;
    }

    selectedCategory.value = category;
    searchQuery.value = '';
    searchController.clear();

    // Search by category name
    await searchProducts(category);
    // Restore selected category since searchProducts clears it
    selectedCategory.value = category;
  }

  void toggleViewMode() {
    isGridView.value = !isGridView.value;
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    _connectivitySub?.cancel();
    super.onClose();
  }
}
