import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RequestMallPromotionsService {
  final Dio _dio;

  RequestMallPromotionsService(this._dio);

  Future<Response?> mallPromotions(String buildingId) async {
    try {
      return await _dio.get('/api/aina/promotions', queryParameters: {
        'building_id': buildingId,
      });
    } catch (e) {
      return null;
    }
  }
}

final requestMallPromotionsProvider = Provider<RequestMallPromotionsService>(
  (ref) => RequestMallPromotionsService(ApiClient().dio),
);
