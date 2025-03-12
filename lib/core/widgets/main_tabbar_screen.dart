import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'custom_tabbar.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:easy_localization/easy_localization.dart';

class MainTabBarScreen extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainTabBarScreen({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<MainTabBarScreen> createState() => _MainTabBarScreenState();
}

class _MainTabBarScreenState extends ConsumerState<MainTabBarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, int> _routesToTabIndex = {
    '/malls': 0,
    '/malls/*/promotions': 1,
    '/stores': 2,
    '/malls/*/stores': 2,
    '/malls/*/profile': 3,
  };

  final Map<int, String> _tabIndexToRoutes = {
    0: '/malls',
    1: '/malls/*/promotions', // When clicking promotions tab, stay on current mall's promotions
    2: '/stores',
    3: '/malls/*/profile',
  };

  String _normalizeRoute(String route) {
    // Convert routes like /malls/123/promotions to /malls/*/promotions
    final parts = route.split('/');
    if (parts.length >= 3 && parts[1] == 'malls' && parts.length > 3) {
      if (parts[3] == 'promotions') {
        return '/malls/*/promotions';
      }
      if (parts[3] == 'stores') {
        return '/malls/*/stores';
      }
      if (parts[3] == 'profile') {
        return '/malls/*/profile';
      }
    }
    return route;
  }

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
  void didUpdateWidget(MainTabBarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      print(
          '🔄 Route changed from ${oldWidget.currentRoute} to ${widget.currentRoute}');
      _updateTabIndex();
    }
  }

  void _updateTabIndex() {
    // Clean query parameters from route before normalization
    final routeWithoutQuery = widget.currentRoute.split('?')[0];
    final normalizedRoute = _normalizeRoute(routeWithoutQuery);
    final index = _routesToTabIndex[normalizedRoute] ?? 0;
    print('📊 Updating tab index for route: $normalizedRoute');
    print('📊 New index: $index, Current index: ${_tabController.index}');
    if (_tabController.index != index) {
      print('📊 Setting new tab index: $index');
      _tabController.index = index;
    } else {
      print('📊 Tab index unchanged');
    }
  }

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];
    print('🔄 Attempting to navigate to tab $index (route: $route)');
    print('📍 Current route: ${widget.currentRoute}');

    if (route != null && widget.currentRoute != route) {
      print('✅ Navigation needed: current route differs from target');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clean query parameters from current route
        final currentRouteBase = widget.currentRoute.split('?')[0];
        final parts = currentRouteBase.split('/');

        if (index == 3) {
          // Profile tab
          print('👤 Handling profile tab navigation');
          final authState = ref.read(authProvider);
          if (!authState.isAuthenticated) {
            context.pushNamed('login');
            return;
          }

          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            print('🏢 Mall ID found: $mallId, navigating to profile');
            context.push('/malls/$mallId/profile');
            return;
          }
          print('⚠️ No mall ID found, going to malls');
          context.push('/malls');
          return;
        }

        if (index == 2) {
          // Stores tab
          print('🏪 Handling stores tab navigation');
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            print('🏢 Mall ID found: $mallId, navigating to stores');
            context.push('/malls/$mallId/stores');
            return;
          }
          print('🏪 No mall ID found, going to general stores');
          context.push('/stores');
          return;
        }

        if (index == 0) {
          // Malls tab
          print('🏢 Handling malls tab navigation');
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            print('🏢 Mall ID found: $mallId, navigating to mall details');
            context.push('/malls/$mallId');
            return;
          }
          print('🏢 No mall ID found, going to malls list');
          context.push('/malls');
          return;
        }

        if (index == 1) {
          // Promotions tab
          print('🎯 Handling promotions tab navigation');
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            print('🏢 Mall ID found: $mallId, navigating to promotions');
            context.push('/malls/$mallId/promotions');
            return;
          }
          print('⚠️ No mall ID found, going to malls');
          context.push('/malls');
          return;
        }

        print('🔄 Default navigation to route: $route');
        context.push(route);
      });
    } else {
      print('⚠️ Navigation skipped: same route or null');
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

        print('🔙 Back button pressed');
        print('📍 Current route: $normalizedRoute');
        print('📊 Current tab index: $currentIndex');

        if (currentIndex != 0) {
          print('↩️ Not on first tab, navigating to malls');
          _navigateToTab(0);
        } else {
          print('✅ On first tab, allowing default back behavior');
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: CustomTabBar(tabController: _tabController),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
