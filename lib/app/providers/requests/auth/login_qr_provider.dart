import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/services/api_service.dart';
import 'package:aina_flutter/app/providers/dio_provider.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class LoginQrService {
  final ApiClient apiClient;

  LoginQrService(this.apiClient);

  Future<Response> loginWithQr(String qrToken, String accessToken) async {
    return await apiClient.dio.post(
      '/api/crm/auth/login-qr',
      data: {
        'qr_token': qrToken,
        'access_token': accessToken,
      },
    );
  }
}

final loginQrProvider = Provider<LoginQrService>((ref) {
  return LoginQrService(ApiClient());
});
