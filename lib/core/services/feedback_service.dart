import 'package:aina_flutter/core/models/feedback_category.dart';
import 'package:aina_flutter/core/api/api_client.dart';

class FeedbackService {
  final ApiClient _apiClient;

  FeedbackService(this._apiClient);

  Future<List<FeedbackCategory>> getFeedbackCategories() async {
    try {
      final response =
          await _apiClient.dio.get('/api/promenade/categories/feedback');
      final data = response.data['data'] as List;
      return data
          .map(
              (json) => FeedbackCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitFeedback({
    required int categoryId,
    required String phone,
    required String description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/promenade/feedback',
        data: {
          'category_id': categoryId,
          'phone': phone,
          'description': description,
        },
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}
