import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:aina_flutter/features/home/ui/pages/home_page.dart';
import 'package:aina_flutter/features/home/ui/home_tabbar_screen.dart';
import 'package:aina_flutter/features/home/ui/pages/home_promotions_page.dart';
import 'package:aina_flutter/features/content/ui/pages/event_details_page.dart';
import 'package:aina_flutter/features/home/ui/pages/home_bookings_page.dart';
import 'package:aina_flutter/features/home/ui/pages/home_tickets_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/stores_page.dart';
import 'package:aina_flutter/features/home/ui/pages/menu_page.dart';
import 'package:aina_flutter/shared/navigation/ui/transitions/custom_transitions.dart';

class HomeRoutes {
  // Получает направление перехода из extra данных
  static bool _getSlideDirection(Object? extra, String routeName) {
    final fromRight = extra is Map<String, dynamic>
        ? (extra['fromRight'] as bool? ?? true)
        : true;

    // Debug: Обработка направления (только для новых переходов)
    if (extra != null) {
      debugPrint('🎯 PROCESSING SLIDE DIRECTION for $routeName:');
      debugPrint('   Extra data: $extra');
      debugPrint(
          '   Determined direction: ${fromRight ? 'FROM RIGHT →' : 'FROM LEFT ←'}');
    }

    return fromRight;
  }

  static ShellRoute shellRoute = ShellRoute(
    builder: (context, state, child) {
      return Container(
        color: Colors.black,
        child: HomeTabBarScreen(
          currentRoute: state.uri.toString(),
          child: child,
        ),
      );
    },
    routes: [
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) {
          return CustomPageTransitions.directionalSlideTransition(
            context: context,
            state: state,
            child: const HomePage(),
            fromRight: _getSlideDirection(state.extra, 'home'),
          );
        },
      ),
      GoRoute(
        path: '/promotions',
        name: 'promotions',
        pageBuilder: (context, state) {
          return CustomPageTransitions.directionalSlideTransition(
            context: context,
            state: state,
            child: const HomePromotionsPage(),
            fromRight: _getSlideDirection(state.extra, 'promotions'),
          );
        },
      ),
      GoRoute(
        path: '/events/:id',
        name: 'event_details',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || int.tryParse(id) == null) {
            return const HomePage();
          }
          return EventDetailsPage(id: int.parse(id));
        },
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        pageBuilder: (context, state) {
          return CustomPageTransitions.directionalSlideTransition(
            context: context,
            state: state,
            child: const HomeBookingsPage(),
            fromRight: _getSlideDirection(state.extra, 'bookings'),
          );
        },
      ),
      GoRoute(
        path: '/tickets',
        name: 'home_tickets',
        pageBuilder: (context, state) {
          return CustomPageTransitions.directionalSlideTransition(
            context: context,
            state: state,
            child: const HomeTicketsPage(),
            fromRight: _getSlideDirection(state.extra, 'tickets'),
          );
        },
      ),
      GoRoute(
        path: '/stores',
        name: 'stores',
        pageBuilder: (context, state) {
          return CustomPageTransitions.directionalSlideTransition(
            context: context,
            state: state,
            child: const StoresPage(mallId: 0),
            fromRight: _getSlideDirection(state.extra, 'stores'),
          );
        },
      ),
      GoRoute(
        path: '/menu',
        name: 'menu',
        pageBuilder: (context, state) {
          return CustomPageTransitions.slideTransition(
            context: context,
            state: state,
            child: const MenuPage(),
          );
        },
      ),
    ],
  );
}
