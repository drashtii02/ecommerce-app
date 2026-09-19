import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshProducts,
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        edgeOffset: kToolbarHeight + MediaQuery.of(context).padding.top + 56,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── App Bar ───────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor:
                  isDark ? const Color(0xFF1A1A2E) : const Color(0xFF667EEA),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1A1A2E),
                              const Color(0xFF0F3460)
                            ]
                          : [
                              const Color(0xFF667EEA),
                              const Color(0xFF764BA2)
                            ],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 58),
                title: const Text(
                  'ShopEase',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.favorite_outline, color: Colors.white),
                  onPressed: () => Get.toNamed(AppRoutes.wishlist),
                ),
                Obx(
                  () => IconButton(
                    icon: Icon(
                      themeCtrl.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: Colors.white,
                    ),
                    onPressed: themeCtrl.toggleTheme,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'logout') _handleLogout();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _buildSearchBar(isDark),
              ),
            ),

            // ─── Offline Banner ────────────────────────────
            _buildOfflineBannerSliver(),

            // ─── Background Refresh ────────────────────────
            _buildBackgroundRefreshSliver(isDark),

            // ─── Category Chips ────────────────────────────
            // _buildCategoryChipsSliver(isDark),

            // ─── View Toggle Bar ───────────────────────────
            _buildViewToggleSliver(isDark),

            // ─── Product Content ───────────────────────────
            ..._buildContentSlivers(context, isDark),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Search Bar
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: controller.searchController,
          focusNode: controller.searchFocusNode,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: Colors.white,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search products, brands, categories...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return GestureDetector(
                  onTap: () {
                    controller.searchController.clear();
                    controller.searchProducts('');
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            isCollapsed: false,
            isDense: true,
          ),
          onSubmitted: controller.searchProducts,
          onChanged: (val) {
            if (val.isEmpty) controller.searchProducts('');
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Offline Banner
  // ═══════════════════════════════════════════════════════════
  Widget _buildOfflineBannerSliver() {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (!controller.isOffline.value) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You\'re offline — showing cached data',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Background Refresh Indicator
  // ═══════════════════════════════════════════════════════════
  Widget _buildBackgroundRefreshSliver(bool isDark) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (!controller.isRefreshingInBackground.value) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.15)
              : AppColors.primaryLight.withValues(alpha: 0.08),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Updating products...',
                style: TextStyle(
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Category Chips
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategoryChipsSliver(bool isDark) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final cat = controller.categories[index];
              return Obx(() {
                final isSelected = controller.selectedCategory.value == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      _formatCategory(cat),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => controller.filterByCategory(cat),
                    selectedColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    backgroundColor:
                        isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              });
            },
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // View Toggle (grid/list) — no product count
  // ═══════════════════════════════════════════════════════════
  Widget _buildViewToggleSliver(bool isDark) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.isLoading.value ||
            controller.hasError.value ||
            controller.products.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: Row(
            children: [
              if (controller.showFromCache.value)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.shade900.withValues(alpha: 0.4)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'cached',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.blue.shade200
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: controller.toggleViewMode,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => Icon(
                        controller.isGridView.value
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      )),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Content Slivers (loading / error / empty / grid / list)
  // ═══════════════════════════════════════════════════════════
  List<Widget> _buildContentSlivers(BuildContext context, bool isDark) {
    return [
      Obx(() {
        // Loading
        if (controller.isLoading.value) {
          return const SliverToBoxAdapter(
            child: ShimmerProductGrid(),
          );
        }

        // Error
        if (controller.hasError.value) {
          final isNoInternet =
              controller.errorMessage.value.toLowerCase().contains('internet') ||
              controller.errorMessage.value.toLowerCase().contains('connection');
          return SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              message: controller.errorMessage.value,
              hint: isNoInternet
                  ? 'Will auto-refresh when internet is available'
                  : null,
              icon: isNoInternet
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline,
              onRetry: controller.fetchProducts,
            ),
          );
        }

        // Empty
        if (controller.products.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              message: controller.searchQuery.value.isNotEmpty
                  ? 'No products found for "${controller.searchQuery.value}"'
                  : 'No products available',
              icon: controller.searchQuery.value.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.shopping_bag_outlined,
              onAction: controller.fetchProducts,
              actionLabel: 'Refresh',
            ),
          );
        }

        // Grid view
        if (controller.isGridView.value) {
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 0.52,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ProductCard(product: controller.products[index]);
                },
                childCount: controller.products.length,
              ),
            ),
          );
        }

        // List view
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProductCard(
                  product: controller.products[index],
                  isListMode: true,
                );
              },
              childCount: controller.products.length,
            ),
          ),
        );
      }),

      // Load more indicator
      SliverToBoxAdapter(
        child: Obx(() {
          if (controller.isLoadingMore.value) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (!controller.hasMoreData.value &&
              controller.products.isNotEmpty &&
              !controller.isLoading.value) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'You\'ve seen it all!',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════
  String _formatCategory(String category) {
    return category
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.find<AuthRepository>().logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
