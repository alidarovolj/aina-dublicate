import 'package:go_router/go_router.dart';
import 'package:aina_flutter/features/user/ui/pages/login_page.dart';
import 'package:aina_flutter/features/user/ui/pages/code_page.dart';

class AuthRoutes {
  static List<RouteBase> routes = [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final buildingId =
            (state.extra as Map<String, dynamic>?)?['buildingId'] as String?;
        final buildingType =
            (state.extra as Map<String, dynamic>?)?['buildingType'] as String?;
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
  ];
}
