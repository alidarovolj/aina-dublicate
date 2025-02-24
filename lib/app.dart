import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/router/app_router.dart';
import 'core/styles/theme.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/promenade_profile.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:dio/dio.dart';
import 'core/services/deep_link_service.dart';
import 'package:aina_flutter/core/providers/update_notifier_provider.dart';
import 'package:aina_flutter/core/widgets/update_modal.dart';

// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global route observer for navigation events
final routeObserver = RouteObserver<ModalRoute>();

// Create the promenade profile provider
final promenadeProfileProvider = FutureProvider<PromenadeProfile>((ref) async {
  final authState = ref.read(authProvider);
  if (!authState.isAuthenticated) {
    throw Exception('User is not authenticated');
  }

  try {
    final response = await ApiClient().dio.get(
          '/api/promenade/profile',
          options: Options(
            headers: {'force-refresh': 'true'},
          ),
        );
    if (response.data['success'] == true && response.data['data'] != null) {
      return PromenadeProfile.fromJson(response.data['data']);
    }
    throw Exception('Failed to fetch promenade profile');
  } catch (e) {
    throw Exception('Error fetching promenade profile: $e');
  }
});

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
  DeepLinkService? _deepLinkService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Update API client locale on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiClient().updateLocaleFromContext(context);
      // Initialize deep link service
      _deepLinkService = DeepLinkService(context);
      // Fetch promenade profile if user is authenticated
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);
      if (authState.isAuthenticated) {
        container.read(promenadeProfileProvider);
      }
      // Check for updates
      print('🚀 Инициализация проверки обновлений...');
      container.read(updateNotifierProvider.notifier).checkForUpdates();
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
        scaffoldBackgroundColor: AppColors.primary,
        textTheme: GoogleFonts.latoTextTheme(
          const TextTheme(
            bodyMedium: TextStyle(
              letterSpacing: 0,
              height: 1.3,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.primary,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final updateState = ref.watch(updateNotifierProvider);
            if (updateState.type != UpdateType.none) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (navigatorKey.currentContext != null &&
                    Navigator.canPop(navigatorKey.currentContext!)) {
                  return;
                }
                showDialog(
                  context: navigatorKey.currentContext!,
                  barrierDismissible: updateState.type != UpdateType.hard,
                  builder: (context) => const UpdateModal(),
                );
              });
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
      routerConfig: AppRouter.router,
    );
  }
}
