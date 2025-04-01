import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/blocks/coworking_custom_tabbar.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/shared/navigation/index.dart';

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
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  final Map<String, int> _routesToTabIndex = {
    '/coworking': 0,
    '/coworking/*/details': 0,
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
      if (parts.length == 3) {
        return '/coworking/*/details';
      }
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
      return '/coworking/*/details';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
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

  @override
  void didUpdateWidget(CoworkingTabBarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentRoute != widget.currentRoute) {
      // Очищаем query параметры
      final routeWithoutQuery = widget.currentRoute.split('?')[0];
      final normalizedRoute = _normalizeRoute(routeWithoutQuery);
      final index = _routesToTabIndex[normalizedRoute] ?? 0;

      // Проверяем, находимся ли мы на странице деталей коворкинга
      final parts = routeWithoutQuery.split('/');
      final isDetailsPage = parts.length >= 3 &&
          parts[1] == 'coworking' &&
          (parts.length == 3 || parts[3] == 'details');

      if (_tabController.index != index) {
        setState(() {
          _tabController.index = index;
        });
      } else {
        debugPrint('⚠️ Tab index unchanged');
      }
    }
  }

  void _updateTabIndex() {
    final routeWithoutQuery = widget.currentRoute.split('?')[0];
    final normalizedRoute = _normalizeRoute(routeWithoutQuery);
    final index = _routesToTabIndex[normalizedRoute] ?? 0;

    if (_tabController.index != index) {
      setState(() {
        _tabController.index = index;
      });
    } else {
      debugPrint('⚠️ Tab index unchanged');
    }
  }

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];
    if (route != null && widget.currentRoute != route) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Если мы на странице логина, не выполняем навигацию
        if (widget.currentRoute.startsWith('/login')) {
          return;
        }

        final coworkingId = _getCoworkingId();
        if (coworkingId == null) {
          // Если нет ID коворкинга, переходим на список коворкингов
          context.go('/coworking');
          return;
        }

        // Получаем текущий маршрут без query параметров
        final currentRouteBase = widget.currentRoute.split('?')[0];

        switch (index) {
          case 0:
            // Если мы уже на странице деталей, не выполняем навигацию
            if (currentRouteBase == '/coworking/$coworkingId') return;
            context.push('/coworking/$coworkingId');
            break;
          case 1:
            if (currentRouteBase == '/coworking/$coworkingId/community') return;
            context.push('/coworking/$coworkingId/community');
            break;
          case 2:
            if (currentRouteBase == '/coworking/$coworkingId/services') return;
            context.push('/coworking/$coworkingId/services');
            break;
          case 3:
            if (currentRouteBase == '/coworking/$coworkingId/bookings') return;
            context.push('/coworking/$coworkingId/bookings');
            break;
          case 4:
            final authState = ref.read(authProvider);
            if (!authState.isAuthenticated) {
              // Сохраняем текущий маршрут для возврата после авторизации
              context.push(
                  '/login?redirect=${Uri.encodeComponent(currentRouteBase)}');
              return;
            }
            if (currentRouteBase == '/coworking/$coworkingId/profile') return;
            context.push('/coworking/$coworkingId/profile');
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDetailsPage = _getCoworkingId() != null;
    final normalizedRoute = _normalizeRoute(widget.currentRoute);
    final currentIndex = _routesToTabIndex[normalizedRoute] ?? 0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final coworkingId = _getCoworkingId();
        final currentRouteBase = widget.currentRoute.split('?')[0];

        if (currentIndex != 0) {
          if (coworkingId != null) {
            if (currentRouteBase != '/coworking/$coworkingId') {
              context.go('/coworking/$coworkingId');
            }
          } else {
            context.go('/coworking');
          }
        } else {
          if (currentRouteBase == '/coworking') {
            context.go('/home');
          } else {
            context.pop();
          }
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: isDetailsPage
            ? CoworkingCustomTabBar(
                tabController: _tabController,
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }
}
