import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';

final requestCodeProvider =
    Provider<RequestCodeService>((ref) => RequestCodeService(ApiClient().dio));

class RequestCodeService {
  final Dio _dio;

  RequestCodeService(Dio dio) : _dio = dio;

  Future<String?> _getAuthHeader() async {
    final token = await StorageService.getToken();
    return token != null ? 'Bearer $token' : null;
  }

  Future<Response?> stories() async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/aina/stories',
        options: authHeader != null
            ? Options(headers: {'Authorization': authHeader})
            : null,
      );

      return response;
    } catch (e) {
      return null;
    }
  }
}
