import 'package:aina_flutter/core/api/api_client.dart';

class ConferenceService {
  Future<Map<String, dynamic>> createOrder({
    required String serviceId,
    required String startAt,
    required String endAt,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/promenade/orders',
        data: {
          'service_id': serviceId,
          'start_at': startAt,
          'end_at': endAt,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception('Failed to create order');
    } catch (error) {
      print('Error creating order: $error');
      throw Exception('Failed to create order');
    }
  }
}
