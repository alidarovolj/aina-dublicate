import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/models/store_category.dart';

class RequestStoreCategoriesService {
  final Dio _dio;

  RequestStoreCategoriesService(this._dio);

  Future<Response?> categories(String mallId) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (mallId != "0") {
        queryParams['mall_id'] = mallId;
      }

      return await _dio.get(
        '/api/aina/shop-categories',
        queryParameters: queryParams,
      );
    } catch (e) {
      return null;
    }
  }
}

final requestStoreCategoriesProvider = Provider<RequestStoreCategoriesService>(
  (ref) => RequestStoreCategoriesService(ApiClient().dio),
);

final storeCategoriesProvider =
    FutureProvider.family<List<StoreCategory>, String>(
  (ref, mallId) async {
    final service = ref.read(requestStoreCategoriesProvider);
    final response = await service.categories(mallId);
    if (response == null) return [];

    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data.map((json) => StoreCategory.fromJson(json)).toList();
  },
);
