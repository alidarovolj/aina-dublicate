import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class RequestStoresService {
  final Dio _dio;

  RequestStoresService(this._dio);

  Future<Response?> stores(String mallId,
      {int? page,
      String? categoryId,
      String? searchQuery,
      bool forceRefresh = false}) async {
    try {
      final Map<String, dynamic> queryParams = {};

      // Only add building_id if mallId is not empty
      // This ensures that when "All Malls" is selected (mallId is empty),
      // no building_id parameter is included in the request
      if (mallId.isNotEmpty) {
        queryParams['building_id'] = mallId;
      }

      if (page != null) {
        queryParams['page'] = page;
      }
      if (categoryId != null) {
        queryParams['category_ids[0]'] = categoryId;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      return await _dio.get(
        '/api/aina/organizations',
        queryParameters: queryParams,
        options: forceRefresh
            ? Options(
                headers: {
                  'force-refresh': 'true',
                },
              )
            : null,
      );
    } catch (e) {
      return null;
    }
  }
}

final requestStoresProvider = Provider<RequestStoresService>(
  (ref) => RequestStoresService(ApiClient().dio),
);

final storesProvider = StateNotifierProvider.family<StoresNotifier,
    AsyncValue<List<Map<String, dynamic>>>, String>(
  (ref, mallId) => StoresNotifier(mallId, ref),
);

class StoresNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final String mallId;
  final Ref ref;
  int _currentPage = 1;
  bool _hasMorePages = true;

  StoresNotifier(this.mallId, this.ref) : super(const AsyncValue.loading()) {
    loadInitialStores();
  }

  Future<void> loadInitialStores(
      {String? categoryId,
      String? searchQuery,
      bool forceRefresh = false}) async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(requestStoresProvider).stores(
            mallId,
            page: _currentPage,
            categoryId: categoryId,
            searchQuery: searchQuery,
            forceRefresh: forceRefresh,
          );

      if (response == null) {
        throw Exception('Failed to load stores');
      }

      final List<Map<String, dynamic>> newStores =
          List<Map<String, dynamic>>.from(response.data['data'] ?? []);

      // Check pagination info from meta
      final meta = response.data['meta'];
      if (meta != null) {
        final currentPage = meta['current_page'] as int;
        final lastPage = meta['last_page'] as int;
        _hasMorePages = currentPage < lastPage;
      } else {
        _hasMorePages = false;
      }

      state =
          AsyncValue.data(newStores); // Always set new data for initial load
      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMoreStores({String? categoryId, String? searchQuery}) async {
    if (!_hasMorePages) return;

    try {
      final service = ref.read(requestStoresProvider);
      final response = await service.stores(
        mallId,
        page: _currentPage,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

      if (response == null) {
        throw Exception('Failed to load stores');
      }

      final List<Map<String, dynamic>> newStores =
          List<Map<String, dynamic>>.from(response.data['data'] ?? []);

      // Check pagination info from meta
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
