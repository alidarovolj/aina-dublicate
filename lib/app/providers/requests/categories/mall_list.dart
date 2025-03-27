import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RequestMallCategoriesService {
  final Dio _dio;

  RequestMallCategoriesService(this._dio);

  Future<Response?> mallCategories(String mallId,
      {bool forceRefresh = false}) async {
    try {
      return await _dio.get(
        '/api/aina/categories',
        queryParameters: {
          'building_id': mallId,
          'type': 'ORGANIZATION_MAIN_CATEGORIES',
        },
        options: forceRefresh
            ? Options(
                headers: {
                  'force-refresh': 'true',
                },
              )
            : null,
      );
    } catch (e) {
      return null;
    }
  }
}

final requestMallCategoriesProvider = Provider<RequestMallCategoriesService>(
  (ref) => RequestMallCategoriesService(ApiClient().dio),
);
