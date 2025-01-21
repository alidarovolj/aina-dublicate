import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/category.dart';
import 'package:aina_flutter/core/providers/requests/mall_categories_service.dart';

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

  Future<void> fetchShopCategories() async {
    try {
      state = const AsyncValue.loading();
      final service = ref.read(requestMallCategoriesProvider);
      final categories = await service.mallCategories(
        buildingId: mallId,
        type: 'ORGANIZATION_SHOP_CATEGORIES',
      );
      if (categories != null) {
        state = AsyncValue.data(categories);
      } else {
        state = const AsyncValue.error(
            'Failed to fetch shop categories', StackTrace.empty);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
