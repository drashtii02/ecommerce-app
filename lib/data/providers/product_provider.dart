import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class ProductProvider {
  final ApiClient _apiClient;

  ProductProvider(this._apiClient);

  Future<Map<String, dynamic>> getProducts({
    int skip = 0,
    int limit = ApiEndpoints.pageLimit,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.products,
      queryParams: {'limit': limit, 'skip': skip},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> searchProducts({
    required String query,
    int skip = 0,
    int limit = ApiEndpoints.pageLimit,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchProducts,
      queryParams: {'q': query, 'limit': limit, 'skip': skip},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProductById(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.products}/$id');
    return response.data;
  }
}
