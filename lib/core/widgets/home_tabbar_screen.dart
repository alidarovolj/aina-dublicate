import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'main_custom_tabbar.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'package:aina_flutter/core/services/storage_service.dart';

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
        _navigateToTab(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(HomeTabBarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateTabIndex();
    }
  }

  void _updateTabIndex() {
    final normalizedRoute = _normalizeRoute(widget.currentRoute);
    final index = _routesToTabIndex[normalizedRoute] ?? 0;
    if (_tabController.index != index) {
      _tabController.index = index;
    }
  }

  String _normalizeRoute(String route) {
    final parts = route.split('/');
    if (parts.length >= 4 &&
        parts[1] == 'coworking' &&
        parts[3] == 'bookings') {
      return '/coworking/*/bookings';
    }
    return route;
  }

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];
    if (route != null && widget.currentRoute != route) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Handle menu tab
        if (index == 4) {
          context.push('/menu');
          return;
        }

        // Track main_click event when navigating to home tab
        if (index == 0) {
          final userData = await StorageService.getUserData();
          print('📱 Available user data fields:');
          print('   ${userData?.keys.join(', ')}');

          final userId = userData?['id'] ?? 0;
          final deviceId = userData?['device_id'] ?? 0;

          print('📱 Tracking main_click event:');
          print('   - User ID: $userId');
          print('   - Device ID: $deviceId');
          print('   - Source: main');

          await AmplitudeService().trackMainClick(
            userId: userId,
            deviceId: deviceId,
            source: 'main',
          );
        }

        context.push(route);
      });
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
