import 'package:aina_flutter/shared/ui/widgets/language_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/app/providers/requests/auth/profile.dart';
import 'package:aina_flutter/app/providers/requests/auth/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/shared/ui/blocks/error_refresh_widget.dart';
import 'package:aina_flutter/shared/navigation/index.dart';
import 'package:dio/dio.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> with RouteAware {
  bool _isCheckingAuth = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAuthAndLoadProfile();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Подписываемся на события навигации
    routeObserver.subscribe(this, ModalRoute.of(context)!);

    if (!_isInitialized) {
      _isInitialized = true;
      // Wrap the provider updates in a Future to avoid build-time modifications
      Future(() {
        if (mounted) {
          _refreshProfileData();
        }
      });
    }
  }

  @override
  void dispose() {
    // Отписываемся от событий навигации
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Вызывается, когда пользователь возвращается на эту страницу
  @override
  void didPopNext() {
    super.didPopNext();
    // Повторно проверяем авторизацию при возврате на страницу
    _checkAuthAndLoadProfile();
  }

  Future<void> _checkAuthAndLoadProfile() async {
    if (!mounted) return;

    setState(() {
      _isCheckingAuth = true;
    });

    try {
      final authState = ref.read(authProvider);

      if (authState.isAuthenticated) {
        final profileService = ref.read(promenadeProfileProvider);
        await profileService.getProfile(forceRefresh: true);

        if (mounted) {
          await _refreshProfileData();
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          if (!mounted) return;

          try {
            await ref.read(authProvider.notifier).logout();
          } catch (logoutError) {
            debugPrint('❌ Ошибка при выходе: $logoutError');
          }

          if (mounted) {
            context.push('/login');
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> _refreshProfileData() async {
    if (!mounted) return;

    try {
      ref.invalidate(userProvider);
      ref.invalidate(userTicketsProvider);
      ref.invalidate(promenadeProfileProvider);
      ref.invalidate(profileCacheKeyProvider);

      await Future(() {
        if (!mounted) return;
        try {
          ref.read(profileCacheKeyProvider.notifier).state++;
        } catch (e) {
          debugPrint('❌ Ошибка при обновлении profileCacheKeyProvider: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении данных профиля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    final cacheKey = ref.watch(profileCacheKeyProvider);
    final profileAsync = isAuthenticated
        ? ref.watch(promenadeProfileDataProvider(cacheKey))
        : null;
    final buildingsAsync = ref.watch(buildingsProvider);

    // Проверяем изменение состояния авторизации
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        // Состояние авторизации изменилось
        Future.microtask(() => _checkAuthAndLoadProfile());
      }
    });

    // Дополнительно следим за изменениями в токене
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.token != next.token && next.isAuthenticated) {
        // Токен изменился и пользователь авторизован
        Future.microtask(() => _checkAuthAndLoadProfile());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.black,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'menu.title'.tr(),
                    style: GoogleFonts.lora(fontSize: 22, color: Colors.white),
                  ),
                  const LanguageSwitcher()
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: buildingsAsync.when(
                  loading: () => _buildSkeletonLoader(),
                  error: (error, stack) {
                    final is500Error = error.toString().contains('500') ||
                        error.toString().contains('Internal Server Error');

                    return ErrorRefreshWidget(
                      height: 200,
                      onRefresh: () {
                        Future.microtask(() async {
                          try {
                            ref.refresh(buildingsProvider);
                            await _checkAuthAndLoadProfile();
                          } catch (e) {
                            debugPrint('❌ Ошибка при обновлении меню: $e');
                          }
                        });
                      },
                      errorMessage: is500Error
                          ? 'stories.error.server'.tr()
                          : 'stories.error.loading'.tr(),
                      refreshText: 'common.refresh'.tr(),
                      isCompact: true,
                      isServerError: true,
                      icon: Icons.warning_amber_rounded,
                    );
                  },
                  data: (buildings) {
                    if (_isCheckingAuth ||
                        (isAuthenticated && profileAsync?.isLoading == true)) {
                      return _buildSkeletonLoader();
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isAuthenticated ||
                              profileAsync?.hasError == true) ...[
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'menu.join_aina'.tr(),
                                    style: GoogleFonts.lora(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => context.push('/login'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'menu.authorize'.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isAuthenticated &&
                              profileAsync != null) ...[
                            profileAsync.when(
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                              data: (profile) => Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    if (profile['avatar']?['url'] != null)
                                      Container(
                                        width: 80,
                                        height: 80,
                                        margin:
                                            const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                profile['avatar']['url']),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (profile['firstname']?.isNotEmpty ==
                                                        true &&
                                                    profile['lastname']
                                                            ?.isNotEmpty ==
                                                        true)
                                                ? '${profile['firstname']} ${profile['lastname']}'
                                                : profile['phone']?['masked'] ??
                                                    '',
                                            style: GoogleFonts.lora(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                if (buildings['coworking'] != null) ...[
                                  ...(buildings['coworking'] as List)
                                      .map((coworking) => _buildMenuItem(
                                            context,
                                            '${'buildings.coworking'.tr()} ${coworking.name}',
                                            () => context.pushReplacement(
                                                '/coworking/${coworking.id}'),
                                          )),
                                ],
                                if (buildings['mall'] != null) ...[
                                  ...(buildings['mall'] as List)
                                      .map((mall) => _buildMenuItem(
                                            context,
                                            '${'buildings.mall'.tr()} ${mall.name}',
                                            () => context.pushReplacement(
                                                '/malls/${mall.id}'),
                                          )),
                                ],
                                if (isAuthenticated) ...[
                                  _buildMenuItem(
                                      context,
                                      'menu.notifications'.tr(),
                                      () => context.push('/notifications')),
                                ],
                                const SizedBox(height: 32),
                                _buildMenuItem(
                                  context,
                                  'menu.about'.tr(),
                                  () => context.push('/about'),
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap,
      {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.grey2,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.almostBlack, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.almostBlack,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 20,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: List.generate(
                6,
                (index) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 56,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
