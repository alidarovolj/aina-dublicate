import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/services/feedback_service.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/models/feedback_category.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(ApiClient());
});

final feedbackCategoriesProvider =
    FutureProvider<List<FeedbackCategory>>((ref) async {
  final feedbackService = ref.watch(feedbackServiceProvider);
  return feedbackService.getFeedbackCategories();
});
