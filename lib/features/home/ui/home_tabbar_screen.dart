import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/blocks/main_custom_tabbar.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';

class HomeTabBarScreen extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const HomeTabBarScreen({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<HomeTabBarScreen> createState() => _HomeTabBarScreenState();
}

class _HomeTabBarScreenState extends ConsumerState<HomeTabBarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _previousTabIndex = 0;

  final Map<String, int> _routesToTabIndex = {
    '/home': 0,
    '/promotions': 1,
    '/bookings': 2,
    '/tickets': 3,
    '/menu': 4,
  };

  final Map<int, String> _tabIndexToRoutes = {
    0: '/home',
    1: '/promotions',
    2: '/bookings',
    3: '/tickets',
    4: '/menu',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _updateTabIndex();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        debugPrint('🎵 TAB CONTROLLER LISTENER:');
        debugPrint(
            '   Index changing from ${_tabController.previousIndex} to ${_tabController.index}');
        debugPrint('   Animation: ${_tabController.animation?.value}');
        _navigateToTab(_tabController.index);
      }
    });

    debugPrint('🚀 HOME TAB BAR SCREEN INITIALIZED');
    debugPrint('   Initial route: ${widget.currentRoute}');
    debugPrint('   Initial tab index: ${_tabController.index}');
  }

  @override
  void didUpdateWidget(HomeTabBarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      debugPrint('🔄 HOME TAB BAR SCREEN UPDATED:');
      debugPrint('   Old route: ${oldWidget.currentRoute}');
      debugPrint('   New route: ${widget.currentRoute}');
      _updateTabIndex();
    }
  }

  void _updateTabIndex() {
    final normalizedRoute = _normalizeRoute(widget.currentRoute);
    final index = _routesToTabIndex[normalizedRoute] ?? 0;

    // Debug: Обновление индекса таба
    debugPrint('📍 TAB INDEX UPDATE:');
    debugPrint('   Current route: ${widget.currentRoute}');
    debugPrint('   Normalized route: $normalizedRoute');
    debugPrint('   Tab index: $index');
    debugPrint('   Controller index: ${_tabController.index}');

    if (_tabController.index != index) {
      debugPrint(
          '   🔄 Updating tab controller index from ${_tabController.index} to $index');
      // НЕ обновляем _previousTabIndex здесь, чтобы не сбивать логику направления
      _tabController.index = index;
    } else {
      debugPrint('   ✅ Tab index already correct');
    }
  }

  String _normalizeRoute(String route) {
    final parts = route.split('/');
    if (parts.length >= 4 &&
        parts[1] == 'coworking' &&
        parts[3] == 'bookings') {
      debugPrint('   🔧 Route normalized: $route → /coworking/*/bookings');
      return '/coworking/*/bookings';
    }
    return route;
  }

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];
    if (route != null && widget.currentRoute != route) {
      // Debug: Переход между табами
      debugPrint('🔄 TAB TRANSITION:');
      debugPrint('   From: ${widget.currentRoute} (index: $_previousTabIndex)');
      debugPrint('   To: $route (index: $index)');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Handle menu tab
        if (index == 4) {
          debugPrint('   🎯 Menu tab - using standard navigation');
          context.push('/menu');
          return;
        }

        // Track main_click event when navigating to home tab
        if (index == 0) {
          debugPrint('   📊 Tracking main_click event for home tab');
          final userData = await StorageService.getUserData();

          final userId = userData?['id'] ?? 0;
          final deviceId = userData?['device_id'] ?? 0;

          await AmplitudeService().trackMainClick(
            userId: userId,
            deviceId: deviceId,
            source: 'main',
          );
        }

        // Определяем направление анимации
        final previousIndex = _tabController.previousIndex ?? _previousTabIndex;
        final isMovingRight = index > previousIndex;
        debugPrint(
            '   📊 Previous index: $previousIndex, Current index: $index');
        debugPrint(
            '   🎭 Animation direction: ${isMovingRight ? 'RIGHT →' : 'LEFT ←'}');
        debugPrint(
            '   📦 Extra data: fromRight=$isMovingRight, previousRoute=${widget.currentRoute}');

        // Переходим с информацией о направлении
        context.push(route, extra: {
          'fromRight': isMovingRight,
          'previousRoute': widget.currentRoute,
        });

        // Обновляем previous index после навигации
        _previousTabIndex = index;
      });
    } else {
      debugPrint('⚠️ TAB NAVIGATION SKIPPED: same route or null');
      debugPrint('   Route: $route, Current: ${widget.currentRoute}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final normalizedRoute = _normalizeRoute(widget.currentRoute);
        final currentIndex = _routesToTabIndex[normalizedRoute] ?? 0;

        if (currentIndex != 0) {
          _navigateToTab(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: MainCustomTabBar(tabController: _tabController),
        extendBody: true,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
