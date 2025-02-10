import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/providers/orders_provider.dart';
import 'package:aina_flutter/features/coworking/domain/services/order_service.dart';
import 'package:aina_flutter/core/providers/api_client_provider.dart';
import 'package:aina_flutter/core/router/route_observer.dart';
import 'dart:async';
import 'package:aina_flutter/features/coworking/presentation/widgets/booking_card.dart';
import 'package:shimmer/shimmer.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});

class CoworkingBookingsPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingBookingsPage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<CoworkingBookingsPage> createState() =>
      _CoworkingBookingsPageState();
}

class _CoworkingBookingsPageState extends ConsumerState<CoworkingBookingsPage>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  Timer? _refreshTimer;
  Timer? _debounceTimer;
  bool _isRefreshing = false;
  final _focusNode = FocusNode();
  DateTime? _lastRefreshTime;
  bool _isInitialized = false;

  static const _minRefreshInterval = Duration(seconds: 2);

  Future<void> _debouncedRefresh() async {
    if (!mounted) return;

    // Check if enough time has passed since the last refresh
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minRefreshInterval) {
      debugPrint(
          'BookingsPage: Skipping refresh - too soon since last refresh');
      return;
    }

    if (_isRefreshing) {
      debugPrint('BookingsPage: Skipping refresh - already refreshing');
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      debugPrint('BookingsPage: Executing debounced refresh');
      _isRefreshing = true;
      _lastRefreshTime = DateTime.now();

      try {
        // Generate new refresh key and update providers
        final newRefreshKey = DateTime.now().millisecondsSinceEpoch;
        ref.read(ordersRefreshKeyProvider.notifier).state = newRefreshKey;
        ref.invalidate(activeOrdersProvider(newRefreshKey));
        ref.invalidate(inactiveOrdersProvider(newRefreshKey));
        debugPrint('BookingsPage: Orders refreshed successfully');
      } catch (e) {
        debugPrint('BookingsPage: Error refreshing orders: $e');
      } finally {
        if (mounted) {
          _isRefreshing = false;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _focusNode.addListener(_handleFocusChange);
    Future.microtask(() {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted || _isInitialized) return;
    debugPrint('BookingsPage: Loading initial data');

    try {
      await _debouncedRefresh();
      debugPrint('BookingsPage: Initial data load complete');
      _setupRefreshTimer();
      _isInitialized = true;
    } catch (e) {
      debugPrint('BookingsPage: Error in _loadInitialData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      Future.microtask(() {
        if (mounted) {
          _debouncedRefresh();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  void _setupRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        Future.microtask(() => _debouncedRefresh());
      }
    });
  }

  @override
  void didPush() {
    super.didPush();
    debugPrint('BookingsPage: didPush called');
    Future.microtask(() {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void didPopNext() {
    super.didPopNext();
    debugPrint('BookingsPage: didPopNext called');
    if (mounted) {
      Future.microtask(() {
        if (mounted) {
          _debouncedRefresh();
          _setupRefreshTimer();
        }
      });
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      debugPrint('BookingsPage: Tab changed, refreshing orders');
      Future.microtask(() {
        if (mounted) {
          _debouncedRefresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    _tabController.removeListener(_handleTabChange);
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Focus(
      focusNode: _focusNode,
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 64),
                child: !authState.isAuthenticated
                    ? _buildUnauthorizedState()
                    : _buildAuthorizedState(),
              ),
              CustomHeader(
                title: 'coworking_tabs.bookings'.tr(),
                type: HeaderType.close,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorizedState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              tabAlignment: TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                SizedBox(
                  width: double.infinity,
                  child: Tab(text: 'bookings.active'.tr()),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Tab(text: 'bookings.history'.tr()),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(true),
              _buildBookingsList(false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthorizedState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'bookings.auth_required'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            label: 'bookings.authorize'.tr(),
            type: ButtonType.filled,
            isFullWidth: true,
            onPressed: () {
              context.push('/login');
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'bookings.no_bookings'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomButton(
                label: 'bookings.book_coworking'.tr(),
                type: ButtonType.bordered,
                isFullWidth: true,
                onPressed: () {
                  context.pushNamed(
                    'coworking_services',
                    pathParameters: {'id': widget.coworkingId.toString()},
                  );
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'bookings.book_conference'.tr(),
                type: ButtonType.filled,
                isFullWidth: true,
                onPressed: () {
                  context.pushNamed(
                    'coworking_services',
                    pathParameters: {'id': widget.coworkingId.toString()},
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBookingsList(bool isActive) {
    final refreshKey = ref.watch(ordersRefreshKeyProvider);
    final ordersAsync = ref.watch(
      isActive
          ? activeOrdersProvider(refreshKey)
          : inactiveOrdersProvider(refreshKey),
    );

    return ordersAsync.when(
      loading: () {
        return _buildSkeletonLoader();
      },
      error: (error, stack) {
        return Center(
          child: Text('Error: $error'),
        );
      },
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BookingCard(
                order: order,
                onTimerExpired: (orderId) async {
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    _debouncedRefresh();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[100]!,
                  highlightColor: Colors.grey[300]!,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 200,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 150,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 100,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
