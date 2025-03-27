import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RequestPromotionDetailsService {
  final Dio _dio;

  RequestPromotionDetailsService(this._dio);

  Future<Response?> promotionDetails(String id) async {
    return await _dio.get('/api/aina/promotions/$id');
  }
}

final requestPromotionDetailsProvider =
    Provider<RequestPromotionDetailsService>(
  (ref) => RequestPromotionDetailsService(ApiClient().dio),
);
