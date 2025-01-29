import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

class RequestPromotionsService {
  final Dio _dio;

  RequestPromotionsService(this._dio);

  Future<Response?> promotions() async {
    try {
      return await _dio.get('/api/aina/promotions');
    } catch (e) {
      // print('Error in promotions request: $e');
      return null;
    }
  }
}

final requestPromotionsProvider = Provider<RequestPromotionsService>(
  (ref) => RequestPromotionsService(ApiClient().dio),
);
