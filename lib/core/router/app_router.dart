import 'package:aina_flutter/features/about_app/presentation/pages/about_page.dart';
import 'package:aina_flutter/features/login/presentation/pages/login_page.dart';
import 'package:aina_flutter/features/malls/presentation/pages/main_page.dart';
import 'package:aina_flutter/features/profile/presentation/pages/edit_data.dart';
import 'package:aina_flutter/features/profile/presentation/pages/profile_page.dart';
import 'package:aina_flutter/features/profile/presentation/pages/tickets_page.dart';
import 'package:aina_flutter/features/promotions/presentation/pages/promotion_details_page.dart';
import 'package:aina_flutter/features/stores/presentation/pages/store_details_page.dart';
import 'package:aina_flutter/features/stores/presentation/pages/category_stores_page.dart';
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
import 'package:aina_flutter/features/stores/presentation/pages/stores_page.dart';
import 'package:aina_flutter/features/promotions/presentation/pages/promotion_qr_page.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_page.dart';
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_details_page.dart';
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_bookings_page.dart';
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_profile_page.dart';
import 'package:aina_flutter/core/widgets/coworking_tabbar_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    observers: [ChuckerFlutter.navigatorObserver],
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      // Main mall routes
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
                      if (mallId == null) {
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
                      GoRoute(
                        path: 'tickets',
                        name: 'tickets',
                        builder: (context, state) {
                          final mallId = state.pathParameters['id'];
                          if (mallId == null) {
                            return const Malls();
                          }
                          return TicketsPage(mallId: int.parse(mallId));
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
                    routes: [
                      GoRoute(
                        path: ':promotionId/qr',
                        name: 'promotion_qr',
                        builder: (context, state) {
                          final mallId = state.pathParameters['id'];
                          final promotionId =
                              state.pathParameters['promotionId'];
                          if (mallId == null || promotionId == null) {
                            return const Malls();
                          }
                          return PromotionQrPage(
                            promotionId: int.parse(promotionId),
                            mallId: mallId,
                          );
                        },
                      ),
                    ],
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
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/stores',
            name: 'stores',
            builder: (context, state) => const StoresPage(mallId: 0),
          ),
        ],
      ),
      // Coworking routes
      ShellRoute(
        builder: (context, state, child) {
          return CoworkingTabBarScreen(
            currentRoute: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/coworking',
            name: 'coworking',
            builder: (context, state) => const CoworkingPage(),
          ),
          GoRoute(
            path: '/coworking/:id',
            name: 'coworking_details',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              if (id == null) return const CoworkingPage();
              return CoworkingDetailsPage(id: int.parse(id));
            },
            routes: [
              GoRoute(
                path: 'bookings',
                name: 'coworking_bookings',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  if (id == null) return const CoworkingPage();
                  return CoworkingBookingsPage(coworkingId: int.parse(id));
                },
              ),
              GoRoute(
                path: 'profile',
                name: 'coworking_profile',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  if (id == null) return const CoworkingPage();
                  return CoworkingProfilePage(coworkingId: int.parse(id));
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/storybook',
        builder: (context, state) => const StorybookScreen(),
      ),
      GoRoute(
        path: '/promotions/:id',
        name: 'promotion_details',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return PromotionDetailsPage(id: id);
        },
      ),
      GoRoute(
        path: '/stores/:id',
        name: 'store_details',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return StoreDetailsPage(id: id);
        },
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PhoneNumberInputScreen(),
      ),
      GoRoute(
        path: '/code',
        builder: (context, state) {
          final phoneNumber = (state.extra as String?) ?? '';
          return CodeInputScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/malls/:mallId/profile',
        name: 'mall_profile_root',
        builder: (context, state) {
          final mallId = int.parse(state.pathParameters['mallId']!);
          return ProfilePage(mallId: mallId);
        },
      ),
      GoRoute(
        path: '/malls/:mallId/stores/category/:categoryId',
        name: 'category_stores',
        builder: (context, state) {
          final mallId = state.pathParameters['mallId'] ?? '0';
          final categoryId = state.pathParameters['categoryId'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Магазины';
          return CategoryStoresPage(
            buildingId: mallId,
            categoryId: categoryId,
            title: title,
          );
        },
      ),
    ],
  );
}
