import 'package:go_router/go_router.dart';
import 'package:chucker_flutter/chucker_flutter.dart';

// Import route modules
import 'auth_routes.dart';
import 'home_routes.dart';
import 'mall_routes.dart';
import 'coworking_routes.dart';
import 'misc_routes.dart';

class AppRouter {
  static final router = GoRouter(
    observers: [ChuckerFlutter.navigatorObserver],
    routes: [
      // Authentication routes
      ...AuthRoutes.routes,

      // Home routes (with shell)
      HomeRoutes.shellRoute,

      // Mall routes (with shell)
      MallRoutes.shellRoute,

      // Coworking routes (with shell)
      CoworkingRoutes.shellRoute,

      // Miscellaneous routes
      ...MiscRoutes.routes,
    ],
  );
}
