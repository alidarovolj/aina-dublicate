import 'package:aina_flutter/core/widgets/custom_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';

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

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];
    if (route != null && widget.currentRoute != route) {
      // Schedule navigation for next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Handle profile tab navigation with auth check
        if (index == 3) {
          final authState = ref.read(authProvider.notifier);
          if (!authState.canAccessProfile) {
            context.push('/login');
            return;
          }
          // Extract current mall ID if we're in a mall route
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            context.push('/malls/$mallId/profile');
            return;
          }
          // If not in mall route, go to malls first
          context.push('/malls');
          return;
        }

        // Special handling for stores tab
        if (index == 2) {
          // Extract current mall ID if we're in a mall route
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            if (!widget.currentRoute.endsWith('/stores')) {
              context.push('/malls/$mallId/stores');
            }
            return;
          }
          // If not in a mall route, go to stores
          context.push('/stores');
          return;
        }

        // Special handling for malls tab when in stores or profile
        if (index == 0) {
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            context.push('/malls/$mallId');
            return;
          }
          context.push('/malls');
          return;
        }

        // Special handling for promotions tab
        if (index == 1) {
          // Extract current mall ID if we're in a mall route
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            if (!widget.currentRoute.endsWith('/promotions')) {
              context.push('/malls/$mallId/promotions');
            }
            return;
          }
          // If not in a mall route, go to malls first
          context.push('/malls');
          return;
        }

        if (index == 4) {
          final authState = ref.read(authProvider);
          if (!authState.isAuthenticated) {
            context.push('/login');
            return;
          }
        }
        context.push(route);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomTabBar(tabController: _tabController),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
