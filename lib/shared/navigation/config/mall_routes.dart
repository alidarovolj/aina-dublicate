import 'package:go_router/go_router.dart';
import 'package:aina_flutter/features/main/ui/main_tabbar_screen.dart';
import 'package:aina_flutter/features/stores/ui/pages/main_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/mall_details_page.dart';
import 'package:aina_flutter/features/user/ui/pages/profile_page.dart';
import 'package:aina_flutter/features/user/ui/pages/edit_data.dart';
import 'package:aina_flutter/features/stores/ui/pages/promotions_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/stores_page.dart';
import 'package:aina_flutter/features/content/ui/pages/events_page.dart';

class MallRoutes {
  static ShellRoute shellRoute = ShellRoute(
    builder: (context, state, child) {
      return MainTabBarScreen(
        currentRoute: state.uri.toString(),
        child: child,
      );
    },
    routes: [
      GoRoute(
        path: '/malls',
        name: 'malls',
        builder: (context, state) => const Malls(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'mall_details',
            builder: (context, state) {
              final mallId = state.pathParameters['id'];
              if (mallId == null) {
                return const Malls();
              }
              if (mallId.isEmpty) {
                return const Malls();
              }
              try {
                return MallDetailsPage(mallId: int.parse(mallId));
              } catch (e) {
                return const Malls();
              }
            },
            routes: [
              GoRoute(
                path: 'profile',
                name: 'mall_profile',
                builder: (context, state) {
                  final mallId = state.pathParameters['id'];
                  if (mallId == null || int.tryParse(mallId) == null) {
                    return const Malls();
                  }
                  return ProfilePage(mallId: int.parse(mallId));
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'mall_edit',
                    builder: (context, state) {
                      final mallId = state.pathParameters['id'];
                      if (mallId == null) {
                        return const Malls();
                      }
                      return EditDataPage(mallId: int.parse(mallId));
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'promotions',
                name: 'mall_promotions',
                builder: (context, state) {
                  final mallId = state.pathParameters['id'];
                  if (mallId == null || mallId.isEmpty) {
                    return const Malls();
                  }
                  try {
                    return PromotionsPage(mallId: int.parse(mallId));
                  } catch (e) {
                    return const Malls();
                  }
                },
              ),
              GoRoute(
                path: 'stores',
                name: 'mall_stores',
                builder: (context, state) {
                  final mallId = state.pathParameters['id'];
                  if (mallId == null) {
                    return const Malls();
                  }
                  return StoresPage(mallId: int.parse(mallId));
                },
                routes: [
                  GoRoute(
                    path: 'categories',
                    name: 'mall_shop_categories',
                    builder: (context, state) {
                      final mallId = state.pathParameters['id'];
                      if (mallId == null) {
                        return const Malls();
                      }
                      return StoresPage(mallId: int.parse(mallId));
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'events',
                name: 'mall_events',
                builder: (context, state) {
                  final mallId = state.pathParameters['id'];
                  if (mallId == null || int.tryParse(mallId) == null) {
                    return const Malls();
                  }
                  return EventsPage(mallId: mallId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
