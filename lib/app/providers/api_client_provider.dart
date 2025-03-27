import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final apiClient = ApiClient();

  // We'll update locale through the widget tree instead
  return apiClient;
});
