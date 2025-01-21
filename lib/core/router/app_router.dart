import 'package:aina_flutter/features/malls/presentation/pages/main_page.dart';
import 'package:go_router/go_router.dart';
// import 'package:aina_flutter/core/services/storage_service.dart';
import 'package:aina_flutter/features/home/presentation/pages/home_page.dart';
import 'package:aina_flutter/features/storybook/presentation/pages/storybook.dart';
import 'package:aina_flutter/core/widgets/main_tabbar_screen.dart';
// import 'package:aina_flutter/features/login/presentation/pages/login_page.dart';
import 'package:aina_flutter/features/login/presentation/pages/code_page.dart';
import 'package:aina_flutter/features/login/presentation/pages/set_info_page.dart';
// import 'package:aina_flutter/features/promotions/presentation/pages/promotion_details_page.dart';
import 'package:aina_flutter/features/malls/presentation/pages/mall_details_page.dart';
import 'package:aina_flutter/features/promotions/presentation/pages/promotions_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/code',
        name: 'auth-code',
        builder: (context, state) {
          final phoneNumber = (state.extra as String?) ?? '';
          return CodeInputScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/info',
        name: 'set-info',
        builder: (context, state) {
          final phoneNumber = (state.extra as String?) ?? '';
          return SetInfoPage(phoneNumber: phoneNumber);
        },
      ),
      ShellRoute(
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
                  final mallId = int.parse(state.pathParameters['id'] ?? '0');
                  return MallDetailsPage(mallId: mallId);
                },
                routes: [
                  GoRoute(
                    path: 'promotions',
                    name: 'mall_promotions',
                    builder: (context, state) {
                      final mallId =
                          int.parse(state.pathParameters['id'] ?? '0');
                      return PromotionsPage(mallId: mallId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // GoRoute(
          //   path: '/promotions/:id',
          //   name: 'promotion_details',
          //   builder: (context, state) {
          //     final promotionId = int.parse(state.pathParameters['id'] ?? '0');
          //     return PromotionDetailsPage(promotionId: promotionId);
          //   },
          // ),
        ],
      ),
      GoRoute(
        path: '/storybook',
        builder: (context, state) => const StorybookScreen(),
      ),
    ],
  );
}
