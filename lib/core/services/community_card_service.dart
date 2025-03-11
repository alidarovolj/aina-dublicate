import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

class CommunityCardService {
  final _apiClient = ApiClient();

  Future<Map<String, dynamic>> getCommunityCard(
      {bool forceRefresh = false}) async {
    try {
      // print('Fetching community card data...');
      final response = await _apiClient.dio.get(
        '/api/promenade/community-card',
        options: Options(
          headers: forceRefresh ? {'force-refresh': 'true'} : null,
        ),
      );
      // print('Response received: ${response.data}');

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception('Invalid response format from server');
    } catch (e) {
      // print('Error fetching community card: $e');
      throw Exception('Failed to get community card: $e');
    }
  }

  Future<void> updateCommunityCard(dynamic data) async {
    try {
      await _apiClient.dio.post(
        '/api/promenade/community-card',
        data: data is FormData ? data : FormData.fromMap(data),
      );
    } catch (e) {
      throw Exception('Failed to update community card: $e');
    }
  }

  Future<void> updateVisibility(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post(
        '/api/promenade/community-card/update-visibility',
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to update visibility: $e');
    }
  }
}

final communityCardServiceProvider = Provider<CommunityCardService>(
  (ref) => CommunityCardService(),
);
