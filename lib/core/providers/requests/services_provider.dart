import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/service.dart';
import 'package:aina_flutter/core/api/api_client.dart';

final servicesProvider = FutureProvider<List<Service>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/api/promenade/services/categories');

  if (response.data['success'] == true) {
    final List<dynamic> data = response.data['data'];
    return data.map((item) => Service.fromJson(item)).toList();
  }

  throw Exception('Failed to load services');
});

final serviceDetailsProvider =
    FutureProvider.family<List<Service>, String>((ref, categoryId) async {
  final api = ApiClient();
  final response =
      await api.dio.get('/api/promenade/services', queryParameters: {
    'type': 'DEFAULT',
    'category_id': categoryId,
  });

  if (response.data['success'] == true) {
    final List<dynamic> data = response.data['data'];
    return data.map((item) => Service.fromJson(item)).toList();
  }

  throw Exception('Failed to load service details');
});
