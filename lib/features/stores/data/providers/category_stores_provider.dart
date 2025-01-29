import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/stores/domain/models/store.dart';

class CategoryStoresService {
  final Dio _dio;

  CategoryStoresService(this._dio);

  Future<Response?> getStores({
    required String buildingId,
    required String categoryId,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get(
        '/api/aina/organizations',
        queryParameters: {
          'building_id': buildingId,
          'category_ids[0]': categoryId,
          'per_page': perPage,
          'page': page,
        },
      );
      return response;
    } catch (e) {
      // print('Error in category stores request: $e');
      return null;
    }
  }
}

final categoryStoresServiceProvider = Provider<CategoryStoresService>(
  (ref) => CategoryStoresService(ApiClient().dio),
);

final categoryStoresProvider = StateNotifierProvider.family<
    CategoryStoresNotifier,
    AsyncValue<List<Store>>,
    ({String buildingId, String categoryId})>(
  (ref, params) => CategoryStoresNotifier(
    ref: ref,
    buildingId: params.buildingId,
    categoryId: params.categoryId,
  ),
);

class CategoryStoresNotifier extends StateNotifier<AsyncValue<List<Store>>> {
  final Ref ref;
  final String buildingId;
  final String categoryId;
  int _currentPage = 1;
  bool _hasMorePages = true;

  CategoryStoresNotifier({
    required this.ref,
    required this.buildingId,
    required this.categoryId,
  }) : super(const AsyncValue.loading()) {
    loadInitialStores();
  }

  Future<void> loadInitialStores() async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    await _loadStores();
  }

  Future<void> loadMoreStores() async {
    if (!_hasMorePages) return;
    await _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final response = await ref.read(categoryStoresServiceProvider).getStores(
            buildingId: buildingId,
            categoryId: categoryId,
            page: _currentPage,
          );

      if (response == null) {
        throw Exception('Failed to load stores');
      }

      final List<Store> newStores = (response.data['data'] as List)
          .map((json) => Store.fromJson(json))
          .toList();

      final meta = response.data['meta'];
      if (meta != null) {
        final currentPage = meta['current_page'] as int;
        final lastPage = meta['last_page'] as int;
        _hasMorePages = currentPage < lastPage;
      } else {
        _hasMorePages = false;
      }

      if (_currentPage == 1) {
        state = AsyncValue.data(newStores);
      } else {
        state.whenData((existingStores) {
          state = AsyncValue.data([...existingStores, ...newStores]);
        });
      }

      _currentPage++;
    } catch (error, stack) {
      if (_currentPage == 1) {
        state = AsyncValue.error(error, stack);
      }
    }
  }

  bool get hasMorePages => _hasMorePages;
}
