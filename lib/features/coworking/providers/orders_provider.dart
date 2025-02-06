import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';
import 'dart:async';

// Refresh trigger for orders
final ordersRefreshProvider = StateProvider<int>((ref) => 0);

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderResponse>>> {
  final bool isActive;
  final ApiClient _apiClient;
  Timer? _refreshTimer;

  OrdersNotifier(this.isActive, this._apiClient)
      : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      state = const AsyncValue.loading();

      print('Fetching orders with isActive: $isActive');
      final response = await _apiClient.dio.get(
        '/api/promenade/orders',
        queryParameters: {
          'per_page': 10,
          'page': 1,
          'state_group': isActive ? 'ACTIVE' : 'INACTIVE',
        },
      );

      print('Orders API Response: ${response.data}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        print('Raw orders data: $data');
        final orders =
            data.map((item) => OrderResponse.fromJson(item)).toList();
        print('Parsed orders: ${orders.length}');
        state = AsyncValue.data(orders);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      print('Error loading orders: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    print('Refreshing orders for ${isActive ? 'active' : 'inactive'} list');
    await loadOrders();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final activeOrdersProvider = StateNotifierProvider.autoDispose<OrdersNotifier,
    AsyncValue<List<OrderResponse>>>((ref) {
  print('Creating active orders provider');
  final apiClient = ApiClient();
  final notifier = OrdersNotifier(true, apiClient);

  // Listen to the refresh trigger
  ref.listen(ordersRefreshProvider, (previous, next) {
    print('Active orders refresh triggered');
    notifier.refresh();
  });

  return notifier;
});

final inactiveOrdersProvider = StateNotifierProvider.autoDispose<OrdersNotifier,
    AsyncValue<List<OrderResponse>>>((ref) {
  print('Creating inactive orders provider');
  final apiClient = ApiClient();
  final notifier = OrdersNotifier(false, apiClient);

  // Listen to the refresh trigger
  ref.listen(ordersRefreshProvider, (previous, next) {
    print('Inactive orders refresh triggered');
    notifier.refresh();
  });

  return notifier;
});
