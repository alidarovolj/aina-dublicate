import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/services/community_card_service.dart';

final communityCardProvider = FutureProvider.family<Map<String, dynamic>, bool>(
    (ref, forceRefresh) async {
  final communityCardService = ref.watch(communityCardServiceProvider);
  return communityCardService.getCommunityCard(forceRefresh: forceRefresh);
});

final communityCardVisibilityProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'page_visible': false,
    'phone_visible': false,
  };
});
