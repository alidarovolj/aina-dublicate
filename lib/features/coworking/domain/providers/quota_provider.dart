import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/api_client_provider.dart';
import 'package:aina_flutter/features/coworking/domain/models/quota.dart';

final quotasProvider = FutureProvider.autoDispose<List<Quota>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/api/promenade/profile');

  if (response.data['success'] == true && response.data['data'] != null) {
    final quotas = response.data['data']['quotas'] as List<dynamic>;
    return quotas.map((json) => Quota.fromJson(json)).toList();
  }

  return [];
});
