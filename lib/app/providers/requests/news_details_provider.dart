import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/news.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

final newsDetailsProvider =
    FutureProvider.family<News, String>((ref, id) async {
  final apiClient = ApiClient();
  final response = await apiClient.dio.get('/api/aina/news/$id');
  return News.fromJson(response.data['data']);
});
