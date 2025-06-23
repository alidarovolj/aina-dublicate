import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/features/content/ui/pages/promotion_details_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/store_details_page.dart';
import 'package:aina_flutter/features/content/ui/pages/about_page.dart';
import 'package:aina_flutter/features/core/ui/pages/notifications_page.dart';
import 'package:aina_flutter/features/payment/ui/pages/tickets_page.dart';
import 'package:aina_flutter/features/user/ui/pages/profile_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/category_stores_page.dart';
import 'package:aina_flutter/features/content/ui/pages/news_details_page.dart';
import 'package:aina_flutter/features/coworking/ui/pages/coworking_order_details_page.dart';
import 'package:aina_flutter/features/coworking/model/services/order_service.dart';
import 'package:aina_flutter/app/providers/api_client_provider.dart';
import 'package:aina_flutter/features/core/ui/pages/no_internet_page.dart';
import 'package:aina_flutter/features/user/ui/pages/auth_qr_scan_page.dart';
import 'package:aina_flutter/features/stores/ui/pages/promotion_qr_page.dart';
import 'package:aina_flutter/features/home/ui/pages/home_page.dart';
import 'package:aina_flutter/shared/navigation/ui/transitions/custom_transitions.dart';
import 'package:aina_flutter/features/core/ui/pages/splash_page.dart';

class MiscRoutes {
  static List<RouteBase> routes = [
    // Splash screen
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
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

    // Standalone routes
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
        final referrer =
            state.extra is Map ? (state.extra as Map)['referrer'] : null;

        debugPrint('⚠️ order_details route - URI: ${state.uri}');
        debugPrint('⚠️ order_details route - fromLocation: $fromLocation');
        debugPrint('⚠️ order_details route - state.extra: ${state.extra}');
        debugPrint('⚠️ order_details route - referrer: $referrer');

        // The problem is that state.uri doesn't contain the information about previous route
        // We need to add this information explicitly when navigating
        final extraIsFromCalendar = state.extra is Map &&
            (state.extra as Map)['isFromCalendar'] == true;
        final isFromCalendar =
            fromLocation.contains('calendar') || extraIsFromCalendar;

        debugPrint(
            '⚠️ order_details route - extraIsFromCalendar: $extraIsFromCalendar');
        debugPrint('⚠️ order_details route - isFromCalendar: $isFromCalendar');

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

    GoRoute(
      path: '/auth-qr-scan',
      name: 'auth_qr_scan',
      builder: (context, state) => const AuthQrScanPage(),
    ),
  ];
}
