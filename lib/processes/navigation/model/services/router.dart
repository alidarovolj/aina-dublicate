import 'package:go_router/go_router.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:aina_flutter/app/app.dart' as app;
import '../../config/routes.dart';

/// Router service that configures and provides the application's routing
class RouterService {
  /// Creates the main router configuration for the app
  static final router = GoRouter(
    navigatorKey: app.navigatorKey,
    initialLocation: '/',
    observers: [
      ChuckerFlutter.navigatorObserver,
      app.routeObserver,
    ],
    routes: AppRoutes.all,
  );
}
