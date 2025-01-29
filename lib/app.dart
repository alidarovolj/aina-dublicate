import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/router/app_router.dart';
import 'core/styles/theme.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    super.key,
    this.initialRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: MaterialApp.router(
        title: 'AINA',
        theme: appTheme.copyWith(
          scaffoldBackgroundColor: AppColors.backgroundLight,
          textTheme: GoogleFonts.latoTextTheme(
            const TextTheme(
              bodyMedium: TextStyle(
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
