import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RequestStoreDetailsService {
  final Dio _dio;

  RequestStoreDetailsService(this._dio);

  Future<Response?> getStore(String id) async {
    try {
      return await _dio.get('/api/aina/organizations/$id');
    } catch (e) {
      return null;
    }
  }
}

final requestStoreDetailsProvider = Provider<RequestStoreDetailsService>(
  (ref) => RequestStoreDetailsService(ApiClient().dio),
);

final storeDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) async {
    final service = ref.read(requestStoreDetailsProvider);
    final response = await service.getStore(id);
    if (response == null) return {};

    return response.data['data'] as Map<String, dynamic>;
  },
);
