import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

class RequestMallCategoriesService {
  final Dio _dio;

  RequestMallCategoriesService(this._dio);

  Future<Response?> mallCategories(String mallId) async {
    try {
      return await _dio.get('/api/aina/categories', queryParameters: {
        'building_id': mallId,
        'type': 'ORGANIZATION_MAIN_CATEGORIES',
      });
    } catch (e) {
      // print('Error in mall categories request: $e');
      return null;
    }
  }
}

final requestMallCategoriesProvider = Provider<RequestMallCategoriesService>(
  (ref) => RequestMallCategoriesService(ApiClient().dio),
);
