import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RequestCodeService {
  final Dio _dio;

  RequestCodeService(this._dio);

  Future<Response?> banners() async {
    try {
      return await _dio.get('/api/aina/banners');
    } catch (e) {
      return null;
    }
  }
}

final requestCodeProvider = Provider<RequestCodeService>(
  (ref) => RequestCodeService(ApiClient().dio),
);
