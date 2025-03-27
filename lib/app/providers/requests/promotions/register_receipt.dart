import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RegisterReceiptService {
  final Dio _dio;

  RegisterReceiptService(this._dio);

  Future<Response> registerReceipt(String promotionId, String url) async {
    try {
      final response = await _dio.post(
        '/api/aina/promotions/$promotionId/register-receipt',
        data: {'url': url},
        options: Options(
          validateStatus: (status) => true, // Accept any status code
        ),
      );
      return response;
    } catch (e) {
      rethrow; // Re-throw the error to handle it in the QR page
    }
  }
}

final registerReceiptProvider = Provider<RegisterReceiptService>(
  (ref) => RegisterReceiptService(ApiClient().dio),
);
