import 'package:aina_flutter/pages/general/about_page.dart';
import 'package:aina_flutter/pages/general/login_page.dart';
import 'package:aina_flutter/pages/malls/main_page.dart';
import 'package:aina_flutter/pages/general/edit_data.dart';
import 'package:aina_flutter/pages/general/profile_page.dart';
import 'package:aina_flutter/pages/general/tickets_page.dart';
import 'package:aina_flutter/pages/general/promotion_details_page.dart';
import 'package:aina_flutter/pages/general/event_details_page.dart';
import 'package:aina_flutter/pages/general/events_page.dart';
import 'package:aina_flutter/pages/malls/store_details_page.dart';
import 'package:aina_flutter/pages/malls/category_stores_page.dart';
import 'package:aina_flutter/pages/general/news_details_page.dart';
import 'package:aina_flutter/pages/general/news_list_page.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/pages/home/home_page.dart';
import 'package:aina_flutter/entities/home_tabbar_screen.dart';
import 'package:aina_flutter/entities/main_tabbar_screen.dart';
import 'package:aina_flutter/pages/general/code_page.dart';
import 'package:aina_flutter/pages/malls/mall_details_page.dart';
import 'package:aina_flutter/pages/malls/promotions_page.dart';
import 'package:aina_flutter/pages/malls/stores_page.dart';
import 'package:aina_flutter/pages/malls/promotion_qr_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_bookings_page.dart';
import 'package:aina_flutter/entities/coworking_tabbar_screen.dart';
import 'package:aina_flutter/pages/coworking/coworking_list_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_promotions_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_services_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:aina_flutter/features/coworking/providers/coworking_service_provider.dart'
    as service_provider;
import 'package:aina_flutter/pages/coworking/coworking_service_details_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_calendar_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_profile_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_community_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_biometric_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_camera_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_order_details_page.dart';
import 'package:aina_flutter/features/coworking/domain/services/order_service.dart';
import 'package:aina_flutter/app/providers/api_client_provider.dart';
import 'package:aina_flutter/pages/general/community_card_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_limit_accounts_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_edit_data_page.dart';
import 'package:aina_flutter/pages/coworking/coworking_conference_service_page.dart';
import 'package:aina_flutter/pages/general/splash_page.dart';
import 'package:aina_flutter/pages/home/home_promotions_page.dart';
import 'package:aina_flutter/pages/home/menu_page.dart';
import 'package:aina_flutter/pages/coworking/conference_room_details_page.dart';
import 'package:aina_flutter/pages/home/home_bookings_page.dart';
import 'package:aina_flutter/pages/general/notifications_page.dart';
import 'package:aina_flutter/pages/general/no_internet_page.dart';
import 'package:aina_flutter/shared/navigation/ui/transitions/custom_transitions.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Auth routes (placed at the top level, outside of any ShellRoute)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          final buildingId =
              (state.extra as Map<String, dynamic>?)?['buildingId'] as String?;
          final buildingType = (state.extra
              as Map<String, dynamic>?)?['buildingType'] as String?;
          return PhoneNumberInputScreen(
            buildingId: buildingId,
            buildingType: buildingType,
          );
        },
      ),
      GoRoute(
        path: '/code',
        builder: (context, state) {
          final phoneNumber =
              (state.extra as Map<String, dynamic>)['phoneNumber'] as String? ??
                  '';
          final buildingId =
              (state.extra as Map<String, dynamic>)['buildingId'] as String?;
          final buildingType =
              (state.extra as Map<String, dynamic>)['buildingType'] as String?;
          return CodeInputScreen(
            phoneNumber: phoneNumber,
            buildingId: buildingId,
            buildingType: buildingType,
          );
        },
      ),
      // Main routes with new tabbar
      ShellRoute(
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
            builder: (context, state) => const TicketsPage(),
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
      ),
      // QR Scanner route (independent)
      GoRoute(
        path: '/promotions/:promotionId/qr',
        name: 'promotion_qr',
        builder: (context, state) {
          final promotionId = state.pathParameters['promotionId'];
          final mallId = state.uri.queryParameters['mallId'];
          if (promotionId == null || mallId == null) {
            return const HomePage();
          }
          return PromotionQrPage(
            promotionId: int.parse(promotionId),
            mallId: mallId,
          );
        },
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
      ),
      // Coworking routes
      ShellRoute(
        builder: (context, state, child) {
          // Don't show the tab bar on the login page
          if (state.uri.toString().startsWith('/login')) {
            return child;
          }
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
            name: 'coworking',
            pageBuilder: (context, state) {
              final coworkingId = state.pathParameters['id'];
              if (coworkingId == null || int.tryParse(coworkingId) == null) {
                return CustomPageTransitions.slideTransition(
                  context: context,
                  state: state,
                  child: const HomePage(),
                );
              }
              return CustomPageTransitions.slideTransition(
                context: context,
                state: state,
                child: CoworkingPage(coworkingId: int.parse(coworkingId)),
              );
            },
            routes: [
              GoRoute(
                path: 'community',
                name: 'coworking_community',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CoworkingCommunityPage(coworkingId: id);
                },
              ),
              GoRoute(
                path: 'services',
                name: 'coworking_services',
                builder: (context, state) {
                  final id = state.pathParameters['id'];

                  if (id == null || int.tryParse(id) == null) {
                    return const CoworkingListPage();
                  }

                  final parsedId = int.parse(id);
                  return ServicesPage(coworkingId: parsedId);
                },
              ),
              GoRoute(
                path: 'conference-services/:serviceId',
                name: 'coworking_conference_services',
                builder: (context, state) {
                  final serviceId =
                      int.tryParse(state.pathParameters['serviceId'] ?? '');
                  final coworkingId =
                      int.tryParse(state.pathParameters['id'] ?? '');

                  if (serviceId == null || coworkingId == null) {
                    return const CoworkingListPage();
                  }

                  return Consumer(
                    builder: (context, ref, _) {
                      final serviceAsync = ref.watch(
                          service_provider.coworkingServiceProvider(serviceId));
                      final tariffsAsync = ref.watch(
                          service_provider.coworkingTariffsProvider(serviceId));

                      return serviceAsync.when(
                        loading: () => CoworkingConferenceServicePage
                            .buildSkeletonLoader(),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                        data: (service) => tariffsAsync.when(
                          loading: () => CoworkingConferenceServicePage
                              .buildSkeletonLoader(),
                          error: (error, stack) =>
                              Center(child: Text('Error: $error')),
                          data: (tariffs) => CoworkingConferenceServicePage(
                            service: service,
                            tariffs: tariffs,
                            coworkingId: coworkingId,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: 'conference-rooms/:serviceId/:tariffId',
                name: 'conference_room_details',
                builder: (context, state) {
                  final serviceId =
                      int.tryParse(state.pathParameters['serviceId'] ?? '');
                  final tariffId =
                      int.tryParse(state.pathParameters['tariffId'] ?? '');
                  final coworkingId =
                      int.tryParse(state.pathParameters['id'] ?? '');

                  if (serviceId == null ||
                      tariffId == null ||
                      coworkingId == null) {
                    return const CoworkingListPage();
                  }

                  return Consumer(
                    builder: (context, ref, _) {
                      final tariffAsync = ref.watch(service_provider
                          .coworkingTariffDetailsProvider(tariffId));

                      return tariffAsync.when(
                        loading: () =>
                            ConferenceRoomDetailsPage.buildSkeletonLoader(),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                        data: (tariff) {
                          return ConferenceRoomDetailsPage(
                            tariff: tariff,
                            coworkingId: coworkingId,
                          );
                        },
                      );
                    },
                  );
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
                  final id = int.parse(state.pathParameters['id']!);
                  return CoworkingProfilePage(coworkingId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'coworking_edit_data',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return CoworkingEditDataPage(coworkingId: id);
                    },
                  ),
                  GoRoute(
                    path: 'biometric',
                    name: 'coworking_biometric',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return CoworkingBiometricPage(coworkingId: id);
                    },
                  ),
                  GoRoute(
                    path: 'camera',
                    name: 'biometric_camera',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      if (id == null || int.tryParse(id) == null) {
                        return const CoworkingListPage();
                      }
                      return CoworkingCameraPage(coworkingId: int.parse(id));
                    },
                  ),
                  GoRoute(
                    path: 'community-card',
                    name: 'community_card',
                    builder: (context, state) => const CommunityCardPage(),
                  ),
                  GoRoute(
                    path: 'limit-accounts',
                    name: 'coworking_limit_accounts',
                    builder: (context, state) => LimitAccountsPage(
                      coworkingId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
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
                      int.tryParse(state.pathParameters['serviceId'] ?? '');
                  final coworkingId =
                      int.tryParse(state.pathParameters['id'] ?? '');

                  if (serviceId == null || coworkingId == null) {
                    return const CoworkingListPage();
                  }

                  return Consumer(
                    builder: (context, ref, _) {
                      final serviceAsync = ref.watch(
                          service_provider.coworkingServiceProvider(serviceId));
                      final tariffsAsync = ref.watch(
                          service_provider.coworkingTariffsProvider(serviceId));

                      return serviceAsync.when(
                        loading: () =>
                            CoworkingServiceDetailsPage.buildSkeletonLoader(),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                        data: (service) => tariffsAsync.when(
                          loading: () =>
                              CoworkingServiceDetailsPage.buildSkeletonLoader(),
                          error: (error, stack) =>
                              Center(child: Text('Error: $error')),
                          data: (tariffs) {
                            if (service.subtype == 'COWORKING') {
                              return CoworkingServiceDetailsPage(
                                service: service,
                                tariffs: tariffs,
                                coworkingId: coworkingId,
                              );
                            } else {
                              return CoworkingConferenceServicePage(
                                service: service,
                                tariffs: tariffs,
                                coworkingId: coworkingId,
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
        path: '/promotions/:id',
        name: 'promotion_details',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || int.tryParse(id) == null) {
            return CustomPageTransitions.slideTransition(
              context: context,
              state: state,
              child: const HomePage(),
            );
          }
          return CustomPageTransitions.slideTransition(
            context: context,
            state: state,
            child: PromotionDetailsPage(id: int.parse(id)),
          );
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
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/tickets/:id',
        name: 'tickets',
        builder: (context, state) => TicketsPage(
          isFromQr: state.extra != null
              ? (state.extra as Map)['isFromQr'] as bool?
              : null,
        ),
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
      ),
      // Order details route
      GoRoute(
        path: '/orders/:id',
        name: 'order_details',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) return const HomePage();

          // Check if we came from the calendar page
          final fromLocation = state.uri.toString();
          final isFromCalendar = fromLocation.contains('calendar');

          return Consumer(
            builder: (context, ref, child) {
              final apiClient = ref.read(apiClientProvider);
              return OrderDetailsPage(
                orderId: id,
                orderService: OrderService(apiClient),
                isFromCalendar: isFromCalendar,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/no-internet',
        name: 'no_internet',
        builder: (context, state) => const NoInternetPage(),
      ),
    ],
  );
}
