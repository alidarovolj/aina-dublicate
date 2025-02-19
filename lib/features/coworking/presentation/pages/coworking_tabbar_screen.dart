import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/coworking_custom_tabbar.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';

class CoworkingTabBarScreen extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const CoworkingTabBarScreen({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<CoworkingTabBarScreen> createState() =>
      _CoworkingTabBarScreenState();
}

class _CoworkingTabBarScreenState extends ConsumerState<CoworkingTabBarScreen>
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
    // print('Current route parts: $parts'); // Debug print
    if (parts.length >= 3 && parts[1] == 'coworking') {
      final id = parts[2];
      final isValid = int.tryParse(id) != null;
      if (isValid) {
        _lastKnownCoworkingId = id; // Сохраняем валидный ID
        // print('Found valid coworking ID: $id'); // Debug print
        return id;
      }
    }
    // Возвращаем последний известный ID, если текущий невалиден
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
    // Не обновляем индекс при переходе на логин
    if (oldWidget.currentRoute != widget.currentRoute &&
        !widget.currentRoute.startsWith('/login')) {
      _updateTabIndex();
    }
  }

  void _updateTabIndex() {
    if (widget.currentRoute.startsWith('/login')) {
      return;
    }

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
        if (index == 4) {
          final authState = ref.read(authProvider);
          // Если мы уже на странице логина или переходим на нее, ничего не делаем
          if (widget.currentRoute.startsWith('/login')) {
            return;
          }
          // Проверяем авторизацию и перенаправляем на логин если не авторизован
          if (!authState.isAuthenticated) {
            _tabController.index = 0;
            context.go('/login');
            return;
          }

          // Если авторизован, переходим к профилю
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            context.go('/coworking/$coworkingId/profile');
          } else {
            context.go('/coworking');
          }
          return;
        }

        // Special handling for services tab
        if (index == 2) {
          final authState = ref.read(authProvider);
          if (!authState.isAuthenticated) {
            _tabController.index = 0;
            context.go('/login');
            return;
          }

          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            if (!widget.currentRoute.endsWith('/services')) {
              context.go('/coworking/$coworkingId/services');
            }
            return;
          }
          context.go('/coworking');
          return;
        }

        // Special handling for bookings tab
        if (index == 3) {
          final authState = ref.read(authProvider);
          if (!authState.isAuthenticated) {
            _tabController.index = 0;
            context.go('/login');
            return;
          }

          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            if (!widget.currentRoute.endsWith('/bookings')) {
              context.go('/coworking/$coworkingId/bookings');
            }
            return;
          }
          context.go('/coworking');
          return;
        }

        // Special handling for coworking tab (main tab)
        if (index == 0) {
          final parts = widget.currentRoute.split('/');
          if (parts.length >= 3 && parts[1] == 'coworking') {
            final coworkingId = parts[2];
            context.go('/coworking/$coworkingId');
            return;
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
    return MaterialApp.router(
      builder: (context, child) {
        return SafeArea(
          bottom: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
