import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/processes/community/community_card_service.dart';

final communityCardProvider = FutureProvider.family<Map<String, dynamic>, bool>(
    (ref, forceRefresh) async {
  final communityCardService = ref.watch(communityCardServiceProvider);
  final data =
      await communityCardService.getCommunityCard(forceRefresh: forceRefresh);

  // Ensure the data has a status field
  if (!data.containsKey('status')) {
    data['status'] = null;
  }

  return data;
});

final communityCardVisibilityProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'page_visible': false,
    'phone_visible': false,
  };
});
