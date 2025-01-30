import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/coworking_custom_tabbar.dart';

class CoworkingTabBarScreen extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const CoworkingTabBarScreen({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<CoworkingTabBarScreen> createState() => _CoworkingTabBarScreenState();
}

class _CoworkingTabBarScreenState extends State<CoworkingTabBarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _lastKnownCoworkingId;

  final Map<String, int> _routesToTabIndex = {
    '/coworking': 0,
    '/coworking/*/services': 2,
    '/coworking/*/bookings': 3,
    '/coworking/*/profile': 4,
  };

  final Map<int, String> _tabIndexToRoutes = {
    0: '', // Пустой суффикс для главной страницы
    2: 'services',
    3: 'bookings',
    4: 'profile',
  };

  String _normalizeRoute(String route) {
    final parts = route.split('/');
    if (parts.length >= 3 && parts[1] == 'coworking') {
      // Сохраняем ID коворкинга при нормализации маршрута
      if (parts.length > 2 && int.tryParse(parts[2]) != null) {
        _lastKnownCoworkingId = parts[2];
      }
      if (parts.length > 3) {
        return '/coworking/*/${parts[3]}';
      }
    }
    return route;
  }

  String? _getCurrentCoworkingId() {
    final parts = widget.currentRoute.split('/');
    print('Current route parts: $parts'); // Debug print
    if (parts.length >= 3 && parts[1] == 'coworking') {
      final id = parts[2];
      final isValid = int.tryParse(id) != null;
      if (isValid) {
        _lastKnownCoworkingId = id; // Сохраняем валидный ID
        print('Found valid coworking ID: $id'); // Debug print
        return id;
      }
    }
    // Возвращаем последний известный ID, если текущий невалиден
    print(
        'Using last known coworking ID: $_lastKnownCoworkingId'); // Debug print
    return _lastKnownCoworkingId;
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
    print('Normalized route: $normalizedRoute'); // Debug print
    final index = _routesToTabIndex[normalizedRoute] ?? 0;
    print('Tab index for route: $index'); // Debug print
    if (_tabController.index != index) {
      _tabController.index = index;
    }
  }

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];
    if (route != null && widget.currentRoute != route) {
      // Schedule navigation for next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Special handling for services tab
        if (index == 2) {
          // Extract current coworking ID if we're in a coworking route
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            if (int.tryParse(coworkingId) != null &&
                !widget.currentRoute.endsWith('/services')) {
              context.go('/coworking/$coworkingId/services');
            }
            return;
          }
          // If not in a coworking route, go to coworking list
          context.go('/coworking');
          return;
        }

        // Special handling for bookings tab
        if (index == 3) {
          // Extract current coworking ID if we're in a coworking route
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            if (int.tryParse(coworkingId) != null &&
                !widget.currentRoute.endsWith('/bookings')) {
              context.go('/coworking/$coworkingId/bookings');
            }
            return;
          }
          // If not in a coworking route, go to coworking list
          context.go('/coworking');
          return;
        }

        // Special handling for profile tab
        if (index == 4) {
          // Extract current coworking ID if we're in a coworking route
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            if (int.tryParse(coworkingId) != null &&
                !widget.currentRoute.endsWith('/profile')) {
              context.go('/coworking/$coworkingId/profile');
            }
            return;
          }
          // If not in a coworking route, go to coworking list
          context.go('/coworking');
          return;
        }

        // Special handling for coworking tab (main tab)
        if (index == 0) {
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            if (int.tryParse(coworkingId) != null) {
              context.go('/coworking/$coworkingId');
              return;
            }
          }
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
      bottomNavigationBar: CoworkingCustomTabBar(
        tabController: _tabController,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
