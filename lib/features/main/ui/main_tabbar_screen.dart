import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/blocks/custom_tabbar.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/shared/navigation/index.dart';

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
  // Сохраняем индекс таба перед переходом на авторизацию
  int _lastTabIndexBeforeAuth = 0;

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
    _updateTabFromRoute();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Отслеживаем изменения таба в режиме реального времени
        debugPrint(
            '⚠️ Tab is changing from ${_tabController.previousIndex} to ${_tabController.index}');
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

      debugPrint(
          '⚠️ didUpdateWidget: oldRoute: ${oldWidget.currentRoute}, newRoute: ${widget.currentRoute}, index: $index, current tab: ${_tabController.index}');

      // Проверяем, возвращаемся ли мы с экрана авторизации
      final isComingFromLogin = oldWidget.currentRoute.startsWith('/login') &&
          !widget.currentRoute.startsWith('/login');

      // Проверка, не происходит ли переход на авторизацию
      final isGoingToLogin = !oldWidget.currentRoute.startsWith('/login') &&
          widget.currentRoute.startsWith('/login');

      if (isGoingToLogin) {
        // Запоминаем последний маршрут перед переходом на авторизацию
        debugPrint(
            '⚠️ Going to login screen from route: ${oldWidget.currentRoute}');
      } else if (isComingFromLogin) {
        debugPrint(
            '⚠️ Coming back from login screen, actual route: ${widget.currentRoute}, needs tab index: $index');

        // Принудительно обновляем индекс таба в соответствии с текущим маршрутом
        // Используем Future.delayed для гарантии, что обновление произойдет после всех других событий
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _tabController.index = index;
            });
            debugPrint(
                '⚠️ Delayed force tab index update to $index after login return');
          }
        });
      } else {
        // Обычное обновление индекса таба при изменении маршрута
        if (_tabController.index != index) {
          setState(() {
            _tabController.index = index;
          });
        } else {
          debugPrint('⚠️ Tab index unchanged');
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPop() {
    debugPrint('⚠️ didPop called for route: ${widget.currentRoute}');
    // При выходе со страницы обновляем индекс таба в соответствии с текущим маршрутом
    _updateTabFromRoute();
  }

  @override
  void didPopNext() {
    debugPrint('⚠️ didPopNext called for route: ${widget.currentRoute}');
    // Обновляем индекс при возврате на эту страницу
    _updateTabFromRoute();
  }

  void _updateTabFromRoute() {
    final routeWithoutQuery = widget.currentRoute.split('?')[0];
    final normalizedRoute = _normalizeRoute(routeWithoutQuery);
    final index = _routesToTabIndex[normalizedRoute] ?? 0;

    debugPrint(
        '⚠️ _updateTabFromRoute: currentRoute: ${widget.currentRoute}, normalizedRoute: $normalizedRoute, index: $index, currentTabIndex: ${_tabController.index}');

    if (_tabController.index != index) {
      setState(() {
        _tabController.index = index;
      });
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
            // Сохраняем текущий индекс таба перед переходом на авторизацию
            _lastTabIndexBeforeAuth = _tabController.index;
            debugPrint(
                '⚠️ Saving last tab index before auth: $_lastTabIndexBeforeAuth (from current tab ${_tabController.index})');

            // Сразу возвращаем таб к предыдущему активному состоянию
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  // Возвращаемся к текущему маршруту, который представлен текущим индексом
                  // Это решает проблему с активным табом профиля при перенаправлении на логин
                  final currentIndex = _tabController.index;
                  debugPrint(
                      '⚠️ Immediately reverting tab to current route index: $currentIndex');
                  _tabController.index = currentIndex;
                });
              }
            });

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
    final normalizedRoute = _normalizeRoute(widget.currentRoute);
    final currentIndex = _routesToTabIndex[normalizedRoute] ?? 0;

    // В каждом билде проверяем соответствие индекса таба текущему маршруту
    if (_tabController.index != currentIndex) {
      debugPrint(
          '⚠️ Tab index mismatch in build: controller index ${_tabController.index}, route index $currentIndex, currentRoute: ${widget.currentRoute}');

      // Если мы не переходим на страницу логина, то принудительно обновляем индекс таба
      if (!widget.currentRoute.startsWith('/login')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _tabController.index = currentIndex;
            });
            debugPrint('⚠️ Forced tab index update to $currentIndex in build');
          }
        });
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Проверяем, не возвращаемся ли мы со страницы логина
        if (widget.currentRoute.startsWith('/login')) {
          debugPrint('⚠️ Physical back button pressed on login page');
          // При физическом нажатии кнопки "назад" на странице логина
          // восстанавливаем предыдущую активную вкладку
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final routeWithoutQuery = widget.currentRoute.split('?')[0];
              final normalizedRoute = _normalizeRoute(routeWithoutQuery);
              final index = _routesToTabIndex[normalizedRoute] ?? 0;

              debugPrint(
                  '⚠️ Restoring tab to $index after physical back from login');
              setState(() {
                _tabController.index = index;
              });
            }
          });
          Navigator.of(context).pop();
          return;
        }

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
}
