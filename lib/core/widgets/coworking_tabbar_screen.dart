import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'coworking_custom_tabbar.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';

class CoworkingTabBarScreen extends ConsumerStatefulWidget {
  final String currentRoute;
  final Widget child;

  const CoworkingTabBarScreen({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  ConsumerState<CoworkingTabBarScreen> createState() =>
      _CoworkingTabBarScreenState();
}

class _CoworkingTabBarScreenState extends ConsumerState<CoworkingTabBarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, int> _routesToTabIndex = {
    '/coworking': 0,
    '/coworking/*/community': 1,
    '/coworking/*/services': 2,
    '/coworking/*/bookings': 3,
    '/coworking/*/profile': 4,
  };

  final Map<int, String> _tabIndexToRoutes = {
    0: '/coworking',
    1: '/coworking/*/community',
    2: '/coworking/*/services',
    3: '/coworking/*/bookings',
    4: '/coworking/*/profile',
  };

  String? _getCoworkingId() {
    final pathSegments = Uri.parse(widget.currentRoute).pathSegments;
    if (pathSegments.length >= 2 && pathSegments[0] == 'coworking') {
      return pathSegments[1];
    }
    return null;
  }

  String _normalizeRoute(String route) {
    final parts = route.split('/');
    if (parts.length >= 3 && parts[1] == 'coworking' && parts.length > 3) {
      if (parts[3] == 'community') {
        return '/coworking/*/community';
      }
      if (parts[3] == 'services') {
        return '/coworking/*/services';
      }
      if (parts[3] == 'promotions') {
        return '/coworking/*/promotions';
      }
      if (parts[3] == 'bookings') {
        return '/coworking/*/bookings';
      }
      if (parts[3] == 'profile') {
        return '/coworking/*/profile';
      }
    }
    return route;
  }

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
  void didUpdateWidget(CoworkingTabBarScreen oldWidget) {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.currentRoute.startsWith('/login')) {
          return;
        }

        if (index == 4) {
          // only profile tab requires auth
          final authState = ref.read(authProvider);
          if (!authState.isAuthenticated) {
            context.go('/login');
            return;
          }
        }

        final coworkingId = _getCoworkingId();
        if (coworkingId == null) {
          context.go('/coworking');
          return;
        }

        switch (index) {
          case 0:
            context.goNamed('coworking_details',
                pathParameters: {'id': coworkingId});
            break;
          case 1:
            context.goNamed('coworking_community',
                pathParameters: {'id': coworkingId});
            break;
          case 2:
            context.goNamed('coworking_services',
                pathParameters: {'id': coworkingId});
            break;
          case 3:
            context.goNamed('coworking_bookings',
                pathParameters: {'id': coworkingId});
            break;
          case 4:
            context.goNamed('coworking_profile',
                pathParameters: {'id': coworkingId});
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDetailsPage = _getCoworkingId() != null;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: isDetailsPage
          ? CoworkingCustomTabBar(
              tabController: _tabController,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
