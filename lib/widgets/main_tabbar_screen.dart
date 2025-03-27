import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'custom_tabbar.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/processes/navigation/index.dart';

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
    with SingleTickerProviderStateMixin, RouteAware {
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
      // Clean query parameters from route before normalization
      final routeWithoutQuery = widget.currentRoute.split('?')[0];
      final normalizedRoute = _normalizeRoute(routeWithoutQuery);
      final index = _routesToTabIndex[normalizedRoute] ?? 0;

      // Обновляем индекс таба только если он отличается от текущего
      if (_tabController.index != index) {
        setState(() {
          _tabController.index = index;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  void _updateTabIndex() {
    // Clean query parameters from route before normalization
    final routeWithoutQuery = widget.currentRoute.split('?')[0];
    final normalizedRoute = _normalizeRoute(routeWithoutQuery);
    final index = _routesToTabIndex[normalizedRoute] ?? 0;
    if (_tabController.index != index) {
      _tabController.index = index;
    }
  }

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];

    if (route != null && widget.currentRoute != route) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clean query parameters from current route
        final currentRouteBase = widget.currentRoute.split('?')[0];
        final parts = currentRouteBase.split('/');

        if (index == 3) {
          // Profile tab
          final authState = ref.read(authProvider);
          if (!authState.isAuthenticated) {
            context.pushNamed('login');
            return;
          }

          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            context.push('/malls/$mallId/profile');
            return;
          }
          context.push('/malls');
          return;
        }

        if (index == 2) {
          // Stores tab
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            context.push('/malls/$mallId/stores');
            return;
          }
          context.push('/stores');
          return;
        }

        if (index == 0) {
          // Malls tab
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            context.push('/malls/$mallId');
            return;
          }
          context.push('/malls');
          return;
        }

        if (index == 1) {
          // Promotions tab
          if (parts.length >= 3 && parts[1] == 'malls') {
            final mallId = parts[2];
            context.push('/malls/$mallId/promotions');
            return;
          }
          context.push('/malls');
          return;
        }

        context.push(route);
      });
    } else {
      debugPrint('⚠️ Navigation skipped: same route or null');
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
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Обновляем индекс при возврате на эту страницу
    final routeWithoutQuery = widget.currentRoute.split('?')[0];
    final normalizedRoute = _normalizeRoute(routeWithoutQuery);
    final index = _routesToTabIndex[normalizedRoute] ?? 0;

    if (_tabController.index != index) {
      setState(() {
        _tabController.index = index;
      });
    }
  }
}
