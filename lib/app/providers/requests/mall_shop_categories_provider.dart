import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/category.dart';
import 'package:aina_flutter/app/providers/requests/mall_categories_service.dart';

final mallShopCategoriesProvider = StateNotifierProvider.family<
    MallShopCategoriesProvider, AsyncValue<List<Category>>, String>(
  (ref, mallId) => MallShopCategoriesProvider(ref, mallId),
);

class MallShopCategoriesProvider
    extends StateNotifier<AsyncValue<List<Category>>> {
  final Ref ref;
  final String mallId;

  MallShopCategoriesProvider(this.ref, this.mallId)
      : super(const AsyncValue.loading()) {
    fetchShopCategories();
  }

  Future<void> fetchShopCategories({bool forceRefresh = false}) async {
    // If mallId is empty, we still want to make the request without building_id
    // to get all categories across all malls
    try {
      // Check if the provider is still mounted before updating state
      if (!mounted) return;

      if (forceRefresh) {
        state = const AsyncValue.loading();
      }

      final service = ref.read(requestMallCategoriesProvider);
      final categories = await service.mallCategories(
        buildingId: mallId,
        type: 'ORGANIZATION_SHOP_CATEGORIES',
        forceRefresh: forceRefresh,
      );

      // Check again if the provider is still mounted after the async operation
      if (!mounted) return;

      if (categories != null) {
        state = AsyncValue.data(categories);
      } else {
        state = const AsyncValue.error(
            'Failed to fetch shop categories', StackTrace.empty);
      }
    } catch (error, stackTrace) {
      // Check if the provider is still mounted before updating state with error
      if (!mounted) return;

      state = AsyncValue.error(error, stackTrace);
    }
  }
}
