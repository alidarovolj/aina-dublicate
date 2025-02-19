import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RequestPromotionsService {
  final ApiClient _apiClient;

  RequestPromotionsService(this._apiClient);

  Future<Response> promotions(BuildContext context,
      {bool forceRefresh = false}) async {
    return await _apiClient.dio.get(
      '/api/aina/promotions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': context.locale.languageCode,
          'Language': context.locale.languageCode,
          if (forceRefresh) 'force-refresh': 'true',
        },
      ),
    );
  }
}

final requestPromotionsProvider = Provider<RequestPromotionsService>((ref) {
  return RequestPromotionsService(ApiClient());
});
