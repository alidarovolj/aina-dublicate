import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

class RequestBuildingsService {
  final Dio _dio;

  RequestBuildingsService(this._dio);

  Future<Response?> buildings() async {
    try {
      return await _dio.get('/api/aina/buildings');
    } catch (e) {
      print('Error in buildings request: $e');
      return null;
    }
  }
}

final requestBuildingsProvider = Provider<RequestBuildingsService>(
  (ref) => RequestBuildingsService(ApiClient().dio),
);
