import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/category.dart';
import 'package:aina_flutter/core/api/api_client.dart';

final requestMallCategoriesProvider = Provider<RequestMallCategoriesService>(
  (ref) => RequestMallCategoriesService(ApiClient().dio),
);

class RequestMallCategoriesService {
  final Dio _dio;

  RequestMallCategoriesService(this._dio);

  Future<List<Category>?> mallCategories({
    required String buildingId,
    required String type,
  }) async {
    try {
      final response = await _dio.get(
        '/api/aina/categories',
        queryParameters: {
          'building_id': buildingId,
          'type': type,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((item) => Category.fromJson(item))
            .toList();
      }
      return null;
    } catch (e) {
      // print('Error fetching mall categories: $e');
      return null;
    }
  }
}
