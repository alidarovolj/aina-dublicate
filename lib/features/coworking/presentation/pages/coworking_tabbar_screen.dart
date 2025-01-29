import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/coworking_custom_tabbar.dart';

class CoworkingTabBarScreen extends StatefulWidget {
  final Widget child;
  final String coworkingId;

  const CoworkingTabBarScreen({
    super.key,
    required this.child,
    required this.coworkingId,
  });

  @override
  State<CoworkingTabBarScreen> createState() => _CoworkingTabBarScreenState();
}

class _CoworkingTabBarScreenState extends State<CoworkingTabBarScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final newLocation = _getRouteForIndex(_tabController.index);
      if (newLocation != null && context.mounted) {
        context.go(newLocation);
      }
    }
  }

  String? _getRouteForIndex(int index) {
    final route = _tabIndexToRoutes[index];
    if (route == null) return null;
    return route.replaceAll('*', widget.coworkingId);
  }

  int _calculateSelectedIndex() {
    final String location = GoRouterState.of(context).uri.path;
    final String normalizedPath = location.endsWith('/')
        ? location.substring(0, location.length - 1)
        : location;

    for (final entry in _routesToTabIndex.entries) {
      final pattern = entry.key.replaceAll('*', '[^/]+');
      if (RegExp(pattern).hasMatch(normalizedPath)) {
        return entry.value;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex();
    if (_tabController.index != currentIndex) {
      _tabController.animateTo(currentIndex);
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CoworkingCustomTabBar(
        tabController: _tabController,
      ),
    );
  }
}
