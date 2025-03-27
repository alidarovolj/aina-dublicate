import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/category.dart';
import 'package:aina_flutter/app/providers/requests/categories/mall_list.dart';

class MallCategoriesProvider extends StateNotifier<AsyncValue<List<Category>>> {
  MallCategoriesProvider(this._listService, this.mallId)
      : super(const AsyncValue.loading()) {
    fetchMallCategories();
  }

  final RequestMallCategoriesService _listService;
  final String mallId;

  Future<void> fetchMallCategories({bool forceRefresh = false}) async {
    if (forceRefresh) {
      state = const AsyncValue.loading();
    }

    try {
      final response =
          await _listService.mallCategories(mallId, forceRefresh: forceRefresh);

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch mall categories');
      }

      final List<Category> categories = (response.data['data'] as List)
          .map((json) => Category.fromJson(json))
          .toList();
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final mallCategoriesProvider = StateNotifierProvider.family<
    MallCategoriesProvider, AsyncValue<List<Category>>, String>(
  (ref, mallId) =>
      MallCategoriesProvider(ref.read(requestMallCategoriesProvider), mallId),
);
