import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'main_custom_tabbar.dart';

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
    '/coworking/*/bookings': 2,
    '/menu': 3,
  };

  final Map<int, String> _tabIndexToRoutes = {
    0: '/home',
    1: '/promotions',
    2: '/coworking/*/bookings',
    3: '/menu',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        if (index == 3) {
          final authState = ref.read(authProvider.notifier);
          if (!authState.canAccessProfile) {
            context.go('/login');
            return;
          }
        }

        // Handle bookings tab
        if (index == 2) {
          final buildingsAsync = ref.read(buildingsProvider);
          final buildings = await buildingsAsync.when(
            data: (data) => data,
            loading: () => null,
            error: (_, __) => null,
          );

          if (buildings != null && buildings['coworking'] != null) {
            final coworkings = buildings['coworking'] as List;
            if (coworkings.isNotEmpty) {
              final firstCoworkingId = coworkings[0].id;
              context.go('/coworking/$firstCoworkingId/bookings');
              return;
            }
          }
          // If no coworkings found, go to coworking list
          context.go('/coworking');
          return;
        }

        context.go(route);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: MainCustomTabBar(tabController: _tabController),
      extendBody: true,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
