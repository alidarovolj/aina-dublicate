import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/category.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

final requestMallCategoriesProvider = Provider<RequestMallCategoriesService>(
  (ref) => RequestMallCategoriesService(ApiClient().dio),
);

class RequestMallCategoriesService {
  final Dio _dio;

  RequestMallCategoriesService(this._dio);

  Future<List<Category>?> mallCategories({
    required String buildingId,
    required String type,
    bool forceRefresh = false,
  }) async {
    try {
      // Create query parameters map
      final Map<String, dynamic> queryParams = {
        'type': type,
      };

      // Only add building_id if it's not empty
      if (buildingId.isNotEmpty) {
        queryParams['building_id'] = buildingId;
      }

      final response = await _dio.get(
        '/api/aina/categories',
        queryParameters: queryParams,
        options: forceRefresh
            ? Options(
                headers: {
                  'force-refresh': 'true',
                },
              )
            : null,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((item) => Category.fromJson(item))
            .toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
