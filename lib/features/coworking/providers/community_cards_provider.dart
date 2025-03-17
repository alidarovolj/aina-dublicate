import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/community_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';

final communityCardsProvider =
    FutureProvider.family<List<CommunityCard>, String?>((ref, search) async {
  final token = ref.read(authProvider).token;
  int? userCardId;
  CommunityCard? userCard;

  try {
    debugPrint('Fetching community cards with search: $search');

    // Get user's card to filter it out only if user is authenticated
    if (token != null) {
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
        // Save user's card for later
        userCard = CommunityCard.fromJson(userCardResponse.data['data']);
      }
    }

    final response = await ApiClient().dio.get(
          '/api/promenade/community-cards',
          queryParameters:
              search != null && search.isNotEmpty ? {'name': search} : null,
          options: Options(
            headers: {'force-refresh': 'true'},
          ),
        );

    debugPrint('Community cards response: ${response.data}');

    if (response.data is! Map<String, dynamic> ||
        response.data['success'] != true ||
        response.data['data'] == null) {
      debugPrint('Invalid response format: ${response.data.runtimeType}');
      throw Exception('Invalid API response format');
    }

    final responseData = response.data['data'];
    debugPrint('Response data type: ${responseData.runtimeType}');

    final validItems = <CommunityCard>[];

    // Add user's card first if it exists and is approved
    if (userCard != null) {
      validItems.add(userCard);
    }

    if (responseData is List) {
      debugPrint('Processing list of ${responseData.length} cards');

      for (var i = 0; i < responseData.length; i++) {
        final item = responseData[i];
        debugPrint('Processing item $i: $item');

        if (item is! Map<String, dynamic>) {
          debugPrint(
              'Warning: Invalid item at index $i: $item (type: ${item.runtimeType})');
          continue;
        }

        // Skip user's own card since we already added it
        if (token != null && item['id'] == userCardId) {
          debugPrint('Skipping user\'s own card with id: $userCardId');
          continue;
        }

        try {
          final card = CommunityCard.fromJson(item);
          validItems.add(card);
          debugPrint('Successfully parsed card $i with name: ${card.name}');
        } catch (e, stackTrace) {
          debugPrint('Error parsing item at index $i: $item');
          debugPrint('Parse error: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      debugPrint('Returning ${validItems.length} valid cards');
      return validItems;
    } else if (responseData is Map<String, dynamic> &&
        responseData['data'] is List) {
      final dataList = responseData['data'] as List;

      for (var item in dataList) {
        if (item is Map<String, dynamic>) {
          // Skip user's own card since we already added it
          if (token != null && item['id'] == userCardId) {
            debugPrint('Skipping user\'s own card with id: $userCardId');
            continue;
          }

          try {
            final card = CommunityCard.fromJson(item);
            validItems.add(card);
          } catch (e) {
            debugPrint('Error parsing card: $e');
          }
        }
      }

      return validItems;
    }

    debugPrint('Unexpected data format type: ${responseData.runtimeType}');
    throw Exception('Unexpected data format in API response');
  } catch (e, stackTrace) {
    debugPrint('Failed to fetch community cards: $e');
    debugPrint('Stack trace: $stackTrace');
    throw Exception('Failed to fetch community cards: $e');
  }
});
