import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/custom_button.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/pages/coworking/domain/services/order_service.dart';
import 'package:aina_flutter/app/providers/api_client_provider.dart';
import 'package:aina_flutter/processes/navigation/index.dart';
import 'dart:async';
import 'package:aina_flutter/pages/coworking/presentation/widgets/booking_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/pages/coworking/domain/models/order_response.dart';

// Cache key provider that controls when to refresh the data
final ordersCacheKeyProvider = StateProvider<int>((ref) => 0);

// Store the last successful result
final _lastOrdersResultProvider =
    StateProvider<Map<String, List<OrderResponse>>>((ref) => {
          'active': [],
          'inactive': [],
        });

// Single provider for both active and inactive orders
final ordersProvider =
    FutureProvider.family<Map<String, List<OrderResponse>>, int>(
        (ref, cacheKey) async {
  final orderService = ref.watch(orderServiceProvider);

  // Fetch both active and inactive orders concurrently
  final results = await Future.wait([
    orderService.getOrders(stateGroup: 'ACTIVE', forceRefresh: true),
    orderService.getOrders(stateGroup: 'INACTIVE', forceRefresh: true),
  ]);

  final newResult = {
    'active': results[0].map((item) => OrderResponse.fromJson(item)).toList(),
    'inactive': results[1].map((item) => OrderResponse.fromJson(item)).toList(),
  };

  // Store the successful result
  ref.read(_lastOrdersResultProvider.notifier).state = newResult;
  return newResult;
});

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
  bool _isRefreshing = false;
  final _focusNode = FocusNode();
  bool _isInitialized = false;

  static const _cacheValidDuration = Duration(minutes: 15);
  DateTime? _lastRefreshTime;

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
    return timeSinceLastRefresh > _cacheValidDuration;
  }

  void _refreshData({bool force = false}) {
    if (!mounted || _isRefreshing) {
      return;
    }

    if (!force && !_shouldRefresh) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      _lastRefreshTime = DateTime.now();
      final newCacheKey = _lastRefreshTime!.millisecondsSinceEpoch;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(ordersCacheKeyProvider.notifier).state = newCacheKey;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _focusNode.addListener(_handleFocusChange);

    // Setup periodic refresh timer for active orders
    _setupRefreshTimer();

    // Initial load should always fetch fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        setState(() {
          _isInitialized = true;
        });
        _refreshData(force: true);
      }
    });
  }

  void _setupRefreshTimer() {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Only set up timer if we're on the active orders tab
    if (_tabController.index == 0) {
      _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        if (mounted) {
          _refreshData(force: true);
        }
      });
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _isInitialized && mounted && _shouldRefresh) {
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() {
    super.didPush();
    _refreshData(force: true);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshData(force: true);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _setupRefreshTimer();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Если свайп слева направо (положительная скорость) и достаточно быстрый
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
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
                  onBack: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorizedState() {
    return Column(
      children: [
        Container(
          color: AppColors.bgLight,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
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

  @override
  Widget _buildBookingsList(bool isActive) {
    final cacheKey = ref.watch(ordersCacheKeyProvider);
    final ordersAsync = ref.watch(ordersProvider(cacheKey));

    return ordersAsync.when(
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
      data: (orders) {
        final list = isActive ? orders['active']! : orders['inactive']!;
        if (list.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BookingCard(
                order: list[index],
                onTimerExpired: (orderId) {
                  if (mounted) {
                    _refreshData();
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
                      borderRadius: BorderRadius.circular(4),
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
                                borderRadius: BorderRadius.circular(4),
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
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
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
