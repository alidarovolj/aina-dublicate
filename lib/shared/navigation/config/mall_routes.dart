import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:aina_flutter/features/main/ui/main_tabbar_screen.dart';
import 'package:aina_flutter/features/stores/ui/pages/main_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/mall_details_page.dart';
import 'package:aina_flutter/features/user/ui/pages/profile_page.dart';
import 'package:aina_flutter/features/user/ui/pages/edit_data.dart';
import 'package:aina_flutter/features/stores/ui/pages/promotions_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/stores_page.dart';
import 'package:aina_flutter/features/content/ui/pages/events_page.dart';
import 'package:aina_flutter/shared/navigation/ui/transitions/custom_transitions.dart';

class MallRoutes {
  /// Определяем направление слайда на основе extra данных
  static bool _getSlideDirection(Object? extra, String routeName) {
    final fromRight = (extra as Map<String, dynamic>?)?['fromRight'] ?? true;
    debugPrint('🎯 PROCESSING MALL SLIDE DIRECTION:');
    debugPrint('   Route: $routeName');
    debugPrint('   Extra data: $extra');
    debugPrint('   FromRight: $fromRight');
    return fromRight;
  }

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
        pageBuilder: (context, state) {
          return CustomPageTransitions.directionalSlideTransition(
            context: context,
            state: state,
            child: const Malls(),
            fromRight: _getSlideDirection(state.extra, 'malls'),
          );
        },
        routes: [
          GoRoute(
            path: ':id',
            name: 'mall_details',
            pageBuilder: (context, state) {
              final mallId = state.pathParameters['id'];
              if (mallId == null) {
                return CustomPageTransitions.directionalSlideTransition(
                  context: context,
                  state: state,
                  child: const Malls(),
                  fromRight: _getSlideDirection(state.extra, 'mall_details'),
                );
              }
              if (mallId.isEmpty) {
                return CustomPageTransitions.directionalSlideTransition(
                  context: context,
                  state: state,
                  child: const Malls(),
                  fromRight: _getSlideDirection(state.extra, 'mall_details'),
                );
              }
              try {
                return CustomPageTransitions.directionalSlideTransition(
                  context: context,
                  state: state,
                  child: MallDetailsPage(mallId: int.parse(mallId)),
                  fromRight: _getSlideDirection(state.extra, 'mall_details'),
                );
              } catch (e) {
                return CustomPageTransitions.directionalSlideTransition(
                  context: context,
                  state: state,
                  child: const Malls(),
                  fromRight: _getSlideDirection(state.extra, 'mall_details'),
                );
              }
            },
            routes: [
              GoRoute(
                path: 'profile',
                name: 'mall_profile',
                pageBuilder: (context, state) {
                  final mallId = state.pathParameters['id'];
                  if (mallId == null || int.tryParse(mallId) == null) {
                    return CustomPageTransitions.directionalSlideTransition(
                      context: context,
                      state: state,
                      child: const Malls(),
                      fromRight:
                          _getSlideDirection(state.extra, 'mall_profile'),
                    );
                  }
                  return CustomPageTransitions.directionalSlideTransition(
                    context: context,
                    state: state,
                    child: ProfilePage(mallId: int.parse(mallId)),
                    fromRight: _getSlideDirection(state.extra, 'mall_profile'),
                  );
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
                pageBuilder: (context, state) {
                  final mallId = state.pathParameters['id'];
                  if (mallId == null || mallId.isEmpty) {
                    return CustomPageTransitions.directionalSlideTransition(
                      context: context,
                      state: state,
                      child: const Malls(),
                      fromRight:
                          _getSlideDirection(state.extra, 'mall_promotions'),
                    );
                  }
                  try {
                    return CustomPageTransitions.directionalSlideTransition(
                      context: context,
                      state: state,
                      child: PromotionsPage(mallId: int.parse(mallId)),
                      fromRight:
                          _getSlideDirection(state.extra, 'mall_promotions'),
                    );
                  } catch (e) {
                    return CustomPageTransitions.directionalSlideTransition(
                      context: context,
                      state: state,
                      child: const Malls(),
                      fromRight:
                          _getSlideDirection(state.extra, 'mall_promotions'),
                    );
                  }
                },
              ),
              GoRoute(
                path: 'stores',
                name: 'mall_stores',
                pageBuilder: (context, state) {
                  final mallId = state.pathParameters['id'];
                  if (mallId == null) {
                    return CustomPageTransitions.directionalSlideTransition(
                      context: context,
                      state: state,
                      child: const Malls(),
                      fromRight: _getSlideDirection(state.extra, 'mall_stores'),
                    );
                  }
                  return CustomPageTransitions.directionalSlideTransition(
                    context: context,
                    state: state,
                    child: StoresPage(mallId: int.parse(mallId)),
                    fromRight: _getSlideDirection(state.extra, 'mall_stores'),
                  );
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
