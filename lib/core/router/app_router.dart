import 'package:aina_flutter/features/about_app/presentation/pages/about_page.dart';
import 'package:aina_flutter/features/conference/providers/conference_service_provider.dart';
import 'package:aina_flutter/features/login/presentation/pages/login_page.dart';
import 'package:aina_flutter/features/malls/presentation/pages/main_page.dart';
import 'package:aina_flutter/features/profile/presentation/pages/edit_data.dart';
import 'package:aina_flutter/features/profile/presentation/pages/profile_page.dart';
import 'package:aina_flutter/features/profile/presentation/pages/tickets_page.dart';
import 'package:aina_flutter/features/promotions/presentation/pages/promotion_details_page.dart';
import 'package:aina_flutter/features/stores/presentation/pages/store_details_page.dart';
import 'package:aina_flutter/features/stores/presentation/pages/category_stores_page.dart';
import 'package:aina_flutter/features/news/presentation/pages/news_details_page.dart';
import 'package:aina_flutter/features/news/presentation/pages/news_list_page.dart';
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
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_list_page.dart';
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_promotions_page.dart';
import 'package:aina_flutter/features/services/presentation/pages/services_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:aina_flutter/features/coworking/providers/coworking_service_provider.dart';
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_service_details_page.dart';
import 'package:aina_flutter/features/coworking/presentation/pages/coworking_calendar_page.dart';
import 'package:aina_flutter/features/conference/presentation/pages/conference_service_details_page.dart';
import 'package:aina_flutter/features/conference/domain/models/conference_service.dart';

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
            name: 'coworking_list',
            builder: (context, state) => const CoworkingListPage(),
          ),
          GoRoute(
            path: '/coworking/:id',
            name: 'coworking_details',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              if (id == null || int.tryParse(id) == null) {
                return const CoworkingListPage();
              }
              return CoworkingPage(coworkingId: int.parse(id));
            },
            routes: [
              GoRoute(
                path: 'services',
                name: 'coworking_services',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  print('Router: Building services page with id: $id');
                  print('Router: All path parameters: ${state.pathParameters}');

                  // Validate the ID
                  if (id == null || int.tryParse(id) == null) {
                    print('Router: Invalid ID, redirecting to coworking list');
                    return const CoworkingListPage();
                  }

                  final parsedId = int.parse(id);
                  print('Router: Valid ID found: $parsedId');
                  return ServicesPage(coworkingId: parsedId);
                },
              ),
              GoRoute(
                path: 'bookings',
                name: 'coworking_bookings',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  if (id == null || int.tryParse(id) == null) {
                    return const CoworkingListPage();
                  }
                  return CoworkingBookingsPage(coworkingId: int.parse(id));
                },
              ),
              GoRoute(
                path: 'profile',
                name: 'coworking_profile',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  if (id == null || int.tryParse(id) == null) {
                    return const CoworkingListPage();
                  }
                  return CoworkingProfilePage(coworkingId: int.parse(id));
                },
              ),
              GoRoute(
                path: 'news',
                name: 'coworking_news',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  if (id == null || int.tryParse(id) == null) {
                    return const CoworkingListPage();
                  }
                  return NewsListPage(buildingId: id);
                },
              ),
              GoRoute(
                path: 'promotions',
                name: 'coworking_promotions',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  if (id == null || int.tryParse(id) == null) {
                    return const CoworkingListPage();
                  }
                  return CoworkingPromotionsPage(coworkingId: int.parse(id));
                },
              ),
              GoRoute(
                path: 'services/:serviceId',
                builder: (context, state) {
                  final serviceId =
                      int.parse(state.pathParameters['serviceId']!);
                  final coworkingId = int.parse(state.pathParameters['id']!);

                  return Consumer(
                    builder: (context, ref, _) {
                      final serviceAsync =
                          ref.watch(coworkingServiceProvider(serviceId));
                      final tariffsAsync =
                          ref.watch(coworkingTariffsProvider(serviceId));

                      return serviceAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                        data: (service) => tariffsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) =>
                              Center(child: Text('Error: $error')),
                          data: (tariffs) {
                            if (service.title == 'Доступ в коворкинг') {
                              return CoworkingServiceDetailsPage(
                                service: service,
                                tariffs: tariffs,
                              );
                            } else {
                              return ConferenceServiceDetailsPage(
                                service: ConferenceService(
                                  id: service.id,
                                  title: service.title,
                                  description: service.description,
                                  type: service.type,
                                  image: service.image != null
                                      ? ServiceImage(
                                          id: service.image!.id,
                                          uuid: service.image!.uuid,
                                          url: service.image!.url,
                                          urlOriginal:
                                              service.image!.urlOriginal,
                                          orderColumn:
                                              service.image!.orderColumn,
                                          collectionName:
                                              service.image!.collectionName,
                                        )
                                      : null,
                                  gallery: service.gallery
                                      .map((img) => ServiceImage(
                                            id: img.id,
                                            uuid: img.uuid,
                                            url: img.url,
                                            urlOriginal: img.urlOriginal,
                                            orderColumn: img.orderColumn,
                                            collectionName: img.collectionName,
                                          ))
                                      .toList(),
                                ),
                                tariffs: tariffs
                                    .map((t) => ConferenceTariff(
                                          id: t.id,
                                          type: t.type,
                                          isActive: t.isActive,
                                          categoryId: t.categoryId,
                                          title: t.title,
                                          subtitle: t.subtitle,
                                          price: t.price,
                                          timeUnit: t.timeUnit,
                                          isFixed: t.isFixed,
                                          image: t.image != null
                                              ? ServiceImage(
                                                  id: t.image!.id,
                                                  uuid: t.image!.uuid,
                                                  url: t.image!.url,
                                                  urlOriginal:
                                                      t.image!.urlOriginal,
                                                  orderColumn:
                                                      t.image!.orderColumn,
                                                  collectionName:
                                                      t.image!.collectionName,
                                                )
                                              : null,
                                          description: t.description,
                                          capacity:
                                              20, // Default capacity for conference rooms
                                        ))
                                    .toList(),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: 'calendar/:tariffId',
                name: 'coworking_calendar',
                builder: (context, state) {
                  try {
                    final tariffId =
                        int.parse(state.pathParameters['tariffId']!);
                    final serviceType = state.uri.queryParameters['type'];

                    if (serviceType == 'conference') {
                      return const CoworkingListPage();
                    }

                    return CoworkingCalendarPage(tariffId: tariffId);
                  } catch (e) {
                    return const CoworkingListPage();
                  }
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
      GoRoute(
        path: '/news/:id',
        name: 'news_details',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return NewsDetailsPage(id: id);
        },
      )
    ],
  );
}
