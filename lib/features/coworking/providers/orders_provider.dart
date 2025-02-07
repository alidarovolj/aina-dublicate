import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';
import 'package:aina_flutter/features/coworking/domain/services/cache_service.dart';
import 'dart:async';

// Refresh trigger for orders
final ordersRefreshProvider = StateProvider<int>((ref) => 0);

// Add refresh key to force provider recreation
final ordersRefreshKeyProvider = StateProvider<int>((ref) => 0);

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderResponse>>> {
  final bool isActive;
  final ApiClient _apiClient;
  Timer? _refreshTimer;

  OrdersNotifier(this.isActive, this._apiClient)
      : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    if (!mounted) return;

    try {
      // Try to get cached data first
      final cachedOrders = await CacheService.getCachedOrders(isActive);
      if (cachedOrders.isNotEmpty) {
        state = AsyncValue.data(cachedOrders);
      } else {
        state = const AsyncValue.loading();
      }

      // Fetch fresh data from API
      final response = await _apiClient.dio.get(
        '/api/promenade/orders',
        queryParameters: {
          'per_page': 10,
          'page': 1,
          'state_group': isActive ? 'ACTIVE' : 'INACTIVE',
        },
      );

      if (!mounted) return;

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        final orders =
            data.map((item) => OrderResponse.fromJson(item)).toList();

        // Cache the new data
        await CacheService.cacheOrders(orders, isActive);

        state = AsyncValue.data(orders);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      if (!mounted) return;

      // If we have cached data, keep showing it
      final cachedOrders = await CacheService.getCachedOrders(isActive);
      if (cachedOrders.isNotEmpty) {
        state = AsyncValue.data(cachedOrders);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> refresh() async {
    await loadOrders();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final activeOrdersProvider = StateNotifierProvider.family
    .autoDispose<OrdersNotifier, AsyncValue<List<OrderResponse>>, int>(
        (ref, refreshKey) {
  final apiClient = ApiClient();
  final notifier = OrdersNotifier(true, apiClient);

  // Force refresh on initialization
  Future.microtask(() => notifier.refresh());

  // Listen to the refresh trigger
  ref.listen(ordersRefreshProvider, (previous, next) {
    notifier.refresh();
  });

  return notifier;
});

final inactiveOrdersProvider = StateNotifierProvider.family
    .autoDispose<OrdersNotifier, AsyncValue<List<OrderResponse>>, int>(
        (ref, refreshKey) {
  final apiClient = ApiClient();
  final notifier = OrdersNotifier(false, apiClient);

  // Force refresh on initialization
  Future.microtask(() => notifier.refresh());

  // Listen to the refresh trigger
  ref.listen(ordersRefreshProvider, (previous, next) {
    notifier.refresh();
  });

  return notifier;
});
