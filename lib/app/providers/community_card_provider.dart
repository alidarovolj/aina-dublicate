import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

final communityCardProvider =
    FutureProvider.family<Map<String, dynamic>?, bool>(
        (ref, forceRefresh) async {
  final token = ref.read(authProvider).token;
  if (token == null) return null;

  try {
    final response = await ApiClient().dio.get(
          '/api/promenade/community-card',
          options: Options(
            headers: {
              if (forceRefresh) 'force-refresh': 'true',
            },
          ),
        );

    if (response.data is Map<String, dynamic> &&
        response.data['success'] == true &&
        response.data['data'] != null) {
      return response.data['data'] as Map<String, dynamic>;
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching community card: $e');
    return null;
  }
});

final communityCardVisibilityProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'page_visible': false,
    'phone_visible': false,
  };
});
