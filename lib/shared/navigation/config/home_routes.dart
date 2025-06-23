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

class HomeRoutes {
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
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/promotions',
        name: 'promotions',
        builder: (context, state) => const HomePromotionsPage(),
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
        builder: (context, state) => const HomeBookingsPage(),
      ),
      GoRoute(
        path: '/tickets',
        name: 'home_tickets',
        builder: (context, state) => const HomeTicketsPage(),
      ),
      GoRoute(
        path: '/stores',
        name: 'stores',
        builder: (context, state) => const StoresPage(mallId: 0),
      ),
      GoRoute(
        path: '/menu',
        name: 'menu',
        builder: (context, state) => const MenuPage(),
      ),
    ],
  );
}
