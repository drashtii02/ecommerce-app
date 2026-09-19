import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/product_model.dart';
import '../../modules/cart/cart_controller.dart';
import '../../modules/wishlist/wishlist_controller.dart';
import 'product_detail_controller.dart';

class ProductDetailScreen extends GetView<ProductDetailController> {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistCtrl = Get.find<WishlistController>();
    final cartCtrl = Get.find<CartController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingIndicator(message: 'Loading product...');
        }

        if (controller.hasError.value) {
          return ErrorView(
            message: controller.errorMessage.value,
            onRetry: controller.fetchProduct,
          );
        }

        final product = controller.product.value;
        if (product == null) {
          return const Center(child: Text('Product not found'));
        }

        return CustomScrollView(
          slivers: [
            _buildAppBar(context, product, wishlistCtrl),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(product),
                    const SizedBox(height: 20),
                    _buildProductInfo(context, product),
                    const SizedBox(height: 16),
                    _buildPriceSection(context, product),
                    const SizedBox(height: 16),
                    _buildDetailsChips(context, product),
                    const SizedBox(height: 20),
                    _buildDescription(context, product),
                    const SizedBox(height: 20),
                    _buildAdditionalInfo(context, product),
                    const SizedBox(height: 20),
                    _buildReviews(context, product),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final product = controller.product.value;
        if (product == null || controller.isLoading.value || controller.hasError.value) {
          return const SizedBox.shrink();
        }

        final inCart = cartCtrl.isInCart(product.id);
        final qty = cartCtrl.getQuantity(product.id);

        return Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Price
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${product.discountedPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Cart controls
              Expanded(
                child: inCart
                    ? Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryDark.withValues(alpha: 0.15)
                              : AppColors.primaryLight.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _cartQtyButton(Icons.remove, () => cartCtrl.decrementQuantity(product.id), isDark),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                ),
                              ),
                            ),
                            _cartQtyButton(Icons.add, () => cartCtrl.incrementQuantity(product.id), isDark),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => cartCtrl.addToCart(product),
                          icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _cartQtyButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    ProductModel product,
    WishlistController wishlistCtrl,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Obx(
          () => Hero(
            tag: 'product_${product.id}',
            child: CachedNetworkImage(
              imageUrl: product.images.isNotEmpty
                  ? product.images[controller.selectedImageIndex.value]
                  : product.thumbnail,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.image_not_supported, size: 60),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Obx(
          () => IconButton(
            icon: Icon(
              wishlistCtrl.isInWishlist(product.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: wishlistCtrl.isInWishlist(product.id)
                  ? Colors.red
                  : Colors.white,
            ),
            onPressed: () => wishlistCtrl.toggleWishlist(product.id),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(ProductModel product) {
    if (product.images.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: product.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Obx(
            () => GestureDetector(
              onTap: () => controller.selectImage(index),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.selectedImageIndex.value == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: controller.selectedImageIndex.value == index ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: CachedNetworkImage(
                    imageUrl: product.images[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (product.brand != null) ...[
              Text(
                product.brand!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product.category.capitalizeFirst ?? product.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(5, (i) {
              return Icon(
                i < product.rating.floor()
                    ? Icons.star
                    : i < product.rating
                        ? Icons.star_half
                        : Icons.star_border,
                size: 20,
                color: AppColors.starColor,
              );
            }),
            const SizedBox(width: 6),
            Text(
              '${product.rating} (${product.reviews.length} reviews)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context, ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '\$${product.discountedPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          if (product.discountPercentage > 0) ...[
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '-${product.discountPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: product.availabilityStatus == 'In Stock'
                  ? AppColors.success.withValues(alpha:0.1)
                  : Colors.orange.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.availabilityStatus,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: product.availabilityStatus == 'In Stock'
                    ? AppColors.success
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsChips(BuildContext context, ProductModel product) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _infoChip(Icons.local_shipping_outlined, product.shippingInformation),
        _infoChip(Icons.verified_user_outlined, product.warrantyInformation),
        _infoChip(Icons.assignment_return_outlined, product.returnPolicy),
        _infoChip(Icons.inventory_2_outlined, 'Stock: ${product.stock}'),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDescription(BuildContext context, ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _specRow('SKU', product.sku),
        _specRow('Weight', '${product.weight} kg'),
        _specRow('Dimensions',
            '${product.dimensions.width} x ${product.dimensions.height} x ${product.dimensions.depth} cm'),
        _specRow('Min. Order', '${product.minimumOrderQuantity} units'),
      ],
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(BuildContext context, ProductModel product) {
    if (product.reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews (${product.reviews.length})',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...product.reviews.map((review) => _reviewCard(context, review)),
      ],
    );
  }

  Widget _reviewCard(BuildContext context, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: AppColors.starColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.comment,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
