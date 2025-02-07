import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/news.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/types/news_params.dart';

final newsProvider =
    Provider.family<AsyncValue<NewsResponse>, NewsParams>((ref, params) {
  return ref.watch(_newsProvider(params));
});

final _newsProvider =
    FutureProvider.family<NewsResponse, NewsParams>((ref, params) async {
  final queryParams = <String, dynamic>{
    'page': params.page,
  };

  if (params.buildingId != null) {
    queryParams['building_id'] = params.buildingId;
  }

  final response = await ApiClient().dio.get(
        '/api/aina/news',
        queryParameters: queryParams,
      );

  // print('News API response data type: ${response.data['data'].runtimeType}');
  // print('News API response: ${response.data}');

  if (response.data['success'] == true) {
    final result = NewsResponse.fromJson(response.data);
    // print('Parsed news count: ${result.data.length}');
    // print('First news item: ${result.data.firstOrNull?.title}');
    return result;
  } else {
    throw Exception('Failed to fetch news');
  }
});
