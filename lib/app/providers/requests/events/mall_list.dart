import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RequestMallEventsService {
  final Dio _dio;

  RequestMallEventsService(this._dio);

  Future<Response?> mallEvents(String mallId) async {
    try {
      final response = await _dio.get('/api/aina/events',
          queryParameters: {
            'building_id': mallId,
          },
          options: Options(validateStatus: (status) => status! < 500));
      return response;
    } catch (e) {
      if (e is DioException) {
      } else {}
      return Response(
          requestOptions: RequestOptions(path: '/api/aina/events'),
          data: {
            'success': true,
            'data': {'data': []}
          });
    }
  }
}

final requestMallEventsProvider = Provider<RequestMallEventsService>(
  (ref) => RequestMallEventsService(ApiClient().dio),
);
