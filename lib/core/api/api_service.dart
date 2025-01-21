import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  final ApiClient _client = ApiClient();

  Future<Response> get(String path) async {
    try {
      return await _client.dio.get(path);
    } catch (e) {
      throw Exception('Failed to make GET request: $e');
    }
  }
}
