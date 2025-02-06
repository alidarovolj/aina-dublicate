import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/services/community_card_service.dart';

final communityCardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final communityCardService = ref.watch(communityCardServiceProvider);
  return communityCardService.getCommunityCard();
});

final communityCardVisibilityProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'page_visible': false,
    'phone_visible': false,
  };
});
