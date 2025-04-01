import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/features/coworking/model/models/community_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';

final communityCardsProvider =
    FutureProvider.family<List<CommunityCard>, String?>((ref, search) async {
  final token = ref.read(authProvider).token;
  int? userCardId;
  CommunityCard? userCard;
  final currentPage = ref.watch(communityCardsPageProvider);
  final hasMorePages = ref.watch(communityCardsHasMoreProvider);
  final isLoadingMore = ref.watch(communityCardsLoadingMoreProvider);

  try {
    // Get user's card to filter it out only if user is authenticated and it's the first page
    if (token != null && currentPage == 1) {
      final userCardResponse = await ApiClient().dio.get(
            '/api/promenade/community-card',
            options: Options(
              headers: {'force-refresh': 'true'},
            ),
          );

      if (userCardResponse.data is Map<String, dynamic> &&
          userCardResponse.data['success'] == true &&
          userCardResponse.data['data'] != null) {
        userCardId = userCardResponse.data['data']['id'] as int?;
        userCard = CommunityCard.fromJson(userCardResponse.data['data']);
      }
    } else if (token != null) {
      // For subsequent pages, get userCardId from the first page's data
      final existingItems = ref.read(communityCardsListProvider) ?? [];
      if (existingItems.isNotEmpty) {
        userCardId = existingItems.first.id;
      }
    }

    final response = await ApiClient().dio.get(
          '/api/promenade/community-cards',
          queryParameters: {
            if (search != null && search.isNotEmpty) 'name': search,
            'page': currentPage,
            'per_page': 100,
          },
          options: Options(
            headers: {'force-refresh': 'true'},
          ),
        );

    if (response.data is! Map<String, dynamic> ||
        response.data['success'] != true ||
        response.data['data'] == null) {
      throw Exception('Invalid API response format');
    }

    final responseData = response.data['data'];
    final pagination = response.data['pagination'] as Map<String, dynamic>;

    // Update pagination state
    ref.read(communityCardsHasMoreProvider.notifier).state =
        pagination['has_next_page'] ?? false;
    ref.read(communityCardsLoadingMoreProvider.notifier).state = false;

    final validItems = <CommunityCard>[];

    // Add user's card first if it exists and is approved (only on first page)
    if (currentPage == 1 && userCard != null) {
      validItems.add(userCard);
    }

    if (responseData is List) {
      for (var i = 0; i < responseData.length; i++) {
        final item = responseData[i];

        if (item is! Map<String, dynamic>) {
          continue;
        }

        // Skip user's own card since we already added it
        if (token != null && item['id'] == userCardId) {
          continue;
        }

        try {
          final card = CommunityCard.fromJson(item);
          validItems.add(card);
        } catch (e, stackTrace) {
          debugPrint('Error parsing item at index $i: $item');
          debugPrint('Parse error: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }

    // Update the list of all cards
    if (currentPage == 1) {
      ref.read(communityCardsListProvider.notifier).state = validItems;
      return validItems;
    } else {
      // Для последующих страниц добавляем новые элементы к существующим
      final existingItems = ref.read(communityCardsListProvider) ?? [];
      final updatedItems = [...existingItems, ...validItems];
      ref.read(communityCardsListProvider.notifier).state = updatedItems;
      return updatedItems;
    }
  } catch (e) {
    ref.read(communityCardsLoadingMoreProvider.notifier).state = false;
    throw Exception('Failed to fetch community cards: $e');
  }
});

// Providers for pagination state
final communityCardsPageProvider = StateProvider<int>((ref) => 1);
final communityCardsHasMoreProvider = StateProvider<bool>((ref) => true);
final communityCardsLoadingMoreProvider = StateProvider<bool>((ref) => false);
final communityCardsListProvider =
    StateProvider<List<CommunityCard>?>((ref) => null);
