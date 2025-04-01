import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/navigation/index.dart';
import 'styles/theme.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/promenade_profile.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:aina_flutter/app/providers/update_notifier_provider.dart';
import 'package:aina_flutter/shared/ui/blocks/update_overlay.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:aina_flutter/shared/ui/blocks/connectivity_wrapper.dart';
import 'package:aina_flutter/shared/services/deep_link_service.dart';

// Global navigator key for accessing navigation from anywhere
final navigatorKey = GlobalKey<NavigatorState>();

// Global route observer for navigation events
final routeObserver = RouteObserver<ModalRoute<void>>();

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
  late final DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Update API client locale on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ApiClient().updateLocaleFromContext(context);
      // Initialize deep link service
      _deepLinkService = DeepLinkService(context);
      debugPrint(_deepLinkService.toString());

      // Fetch promenade profile if user is authenticated
      try {
        final container = ProviderScope.containerOf(context);
        final authState = container.read(authProvider);
        if (authState.isAuthenticated && mounted) {
          container.read(promenadeProfileProvider);
        }
      } catch (e) {
        debugPrint('❌ Ошибка при доступе к authProvider: $e');
      }

      // Инициализируем Remote Config и проверяем обновления
      _initializeRemoteConfigAndCheckUpdates();
    });
  }

  // Новый метод для инициализации Remote Config и проверки обновлений
  Future<void> _initializeRemoteConfigAndCheckUpdates() async {
    try {
      // Добавляем небольшую задержку, чтобы убедиться, что Firebase полностью инициализирован
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      if (!mounted) return;

      // Проверяем обновления
      try {
        final container = ProviderScope.containerOf(context);
        await container.read(updateNotifierProvider.notifier).checkForUpdates();
      } catch (e) {
        debugPrint('❌ Ошибка при проверке обновлений: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при инициализации Remote Config: $e');
    }
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
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      child: MaterialApp.router(
        title: 'AINA',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates +
            [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.theme,
        builder: (context, child) {
          // Оборачиваем все приложение в UpdateOverlay и ConnectivityWrapper
          return UpdateOverlay(
            child: ConnectivityWrapper(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        routerConfig: RouterService.router,
      ),
    );
  }
}
