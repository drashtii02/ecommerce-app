import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductDetailController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();

  final product = Rxn<ProductModel>();
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final selectedImageIndex = 0.obs;

  late final int productId;

  @override
  void onInit() {
    super.onInit();
    productId = Get.arguments as int;
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      product.value = await _productRepo.getProductById(productId);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void selectImage(int index) {
    selectedImageIndex.value = index;
  }
}
