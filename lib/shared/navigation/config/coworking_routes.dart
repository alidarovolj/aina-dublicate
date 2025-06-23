import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/features/coworking/ui/coworking_tabbar_screen.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_list_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_page.dart';
import 'package:aina_flutter/features/home/ui/pages/home_page.dart';
import 'package:aina_flutter/shared/navigation/ui/transitions/custom_transitions.dart';
import 'package:aina_flutter/shared/ui/blocks/coworking_community_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_services_page.dart';
import 'package:aina_flutter/features/coworking/model/providers/coworking_service_provider.dart'
    as service_provider;
import 'package:aina_flutter/features/coworking/ui/pages/coworking_conference_service_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_service_details_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/conference_room_details_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_bookings_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_profile_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_edit_data_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_biometric_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_camera_page.dart';
import 'package:aina_flutter/features/user/ui/pages/community_card_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_limit_accounts_page.dart';
import 'package:aina_flutter/features/content/ui/pages/news_list_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_promotions_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_calendar_page.dart';

class CoworkingRoutes {
  static ShellRoute shellRoute = ShellRoute(
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
                    loading: () =>
                        CoworkingConferenceServicePage.buildSkeletonLoader(),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                    data: (service) => tariffsAsync.when(
                      loading: () =>
                          CoworkingConferenceServicePage.buildSkeletonLoader(),
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
                final tariffId = int.parse(state.pathParameters['tariffId']!);

                return CoworkingCalendarPage(tariffId: tariffId);
              } catch (e) {
                return const CoworkingListPage();
              }
            },
          ),
        ],
      ),
    ],
  );
}
