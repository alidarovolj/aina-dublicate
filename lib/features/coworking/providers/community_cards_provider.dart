import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/community_card.dart';

final communityCardsProvider =
    FutureProvider.family<List<CommunityCard>, String?>((ref, search) async {
  final response = await ApiClient().dio.get(
        '/api/promenade/community-cards',
        queryParameters:
            search != null && search.isNotEmpty ? {'name': search} : null,
      );

  if (response.data['success'] == true) {
    final List<dynamic> data = response.data['data'];
    return data.map((item) => CommunityCard.fromJson(item)).toList();
  } else {
    throw Exception('Failed to fetch community cards');
  }
});
