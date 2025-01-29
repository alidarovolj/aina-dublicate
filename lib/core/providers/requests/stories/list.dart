import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/services/storage_service.dart';
import 'package:flutter/foundation.dart';

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
      // print('Stories API response: ${response.data}');
      return response;
    } catch (e) {
      // print('Error fetching stories: $e');
      return null;
    }
  }
}
