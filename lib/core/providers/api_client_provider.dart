import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/api/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final apiClient = ApiClient();

  // We'll update locale through the widget tree instead
  return apiClient;
});
