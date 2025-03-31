import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class CommunityCardService {
  final _apiClient = ApiClient();

  Future<Map<String, dynamic>> getCommunityCard(
      {bool forceRefresh = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/promenade/community-card',
        options: Options(
          headers: forceRefresh ? {'force-refresh': 'true'} : null,
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception('Invalid response format from server');
    } catch (e) {
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

  Future<void> removeMedia(String collectionName) async {
    try {
      await _apiClient.dio.post(
        '/api/promenade/community-card/remove-media',
        data: {
          'collection_name': collectionName,
        },
      );
    } catch (e) {
      throw Exception('Failed to remove media: $e');
    }
  }

  Future<void> uploadMedia(FormData formData) async {
    try {
      await _apiClient.dio.post(
        '/api/promenade/community-card/upload-media',
        data: formData,
      );
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }
}

final communityCardServiceProvider = Provider<CommunityCardService>(
  (ref) => CommunityCardService(),
);
