import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/router/app_router.dart';
import 'core/styles/theme.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/api/api_client.dart';

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({
    super.key,
    this.initialRoute = '/',
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Update API client locale on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiClient().updateLocaleFromContext(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      ApiClient().updateLocaleFromContext(context);
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    if (mounted) {
      ApiClient().updateLocaleFromContext(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AINA',
      localizationsDelegates: context.localizationDelegates +
          [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: appTheme.copyWith(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: GoogleFonts.latoTextTheme(
          const TextTheme(
            bodyMedium: TextStyle(
              letterSpacing: 0,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      builder: (context, child) {
        return SafeArea(
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: AppRouter.router,
    );
  }
}
