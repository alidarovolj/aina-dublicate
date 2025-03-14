import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/providers/requests/auth/profile.dart';
import 'dart:io';
import 'package:aina_flutter/core/widgets/avatar_edit_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:aina_flutter/core/router/route_observer.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final int mallId;

  const ProfilePage({
    super.key,
    required this.mallId,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with RouteAware {
  File? _temporaryAvatar;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    // Проверяем авторизацию сразу при создании виджета
    _checkAuthAndLoadProfile();
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
    print('🔄 Возврат на страницу профиля');
    // Повторно проверяем авторизацию при возврате на страницу
    _checkAuthAndLoadProfile();
  }

  Future<void> _checkAuthAndLoadProfile() async {
    if (!mounted) return;

    print('🔍 Starting _checkAuthAndLoadProfile');
    setState(() {
      _isCheckingAuth = true;
    });

    try {
      print('🔄 Начало проверки авторизации');
      if (!mounted) return;
      final profileService = ref.read(promenadeProfileProvider);

      print('📱 Запрос данных профиля...');
      final result = await profileService.getProfile(forceRefresh: true);
      print('✅ Получен ответ от сервера: $result');
      print('📋 Response type: ${result.runtimeType}');

      if (mounted) {
        print('🔄 Обновление данных профиля...');
        await _refreshProfileData();
        print('✅ Данные профиля обновлены');
      }
    } catch (e, stack) {
      if (!mounted) return;
      print('❌ Ошибка при проверке авторизации: $e');
      print('📚 Stack trace: $stack');

      if (e is DioException) {
        print('🌐 HTTP Status: ${e.response?.statusCode}');
        print('📝 Response data: ${e.response?.data}');
        print('🔍 Error type: ${e.type}');
        print('🔍 Error message: ${e.message}');

        if (e.response?.statusCode == 401) {
          print('🔑 Обнаружена ошибка авторизации 401');
          if (!mounted) return;

          try {
            print('🔄 Попытка выхода из аккаунта...');
            await ref.read(authProvider.notifier).logout();
            print('✅ Выход выполнен успешно');
          } catch (logoutError) {
            print('❌ Ошибка при выходе: $logoutError');
          }

          if (mounted) {
            print('🔄 Перенаправление на страницу входа');
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

    print('🔄 Starting _refreshProfileData');
    try {
      print('🔄 Invalidating providers...');
      ref.invalidate(userProvider);
      ref.invalidate(userTicketsProvider);
      ref.invalidate(promenadeProfileProvider);
      ref.invalidate(profileCacheKeyProvider);

      await Future(() {
        if (!mounted) return;
        try {
          print('🔄 Updating profile cache key...');
          final oldKey = ref.read(profileCacheKeyProvider);
          ref.read(profileCacheKeyProvider.notifier).state++;
          final newKey = ref.read(profileCacheKeyProvider);
          print('🔑 Profile cache key updated: $oldKey -> $newKey');
        } catch (e) {
          print('❌ Ошибка при обновлении profileCacheKeyProvider: $e');
        }
      });

      // Force refresh user data
      print('🔄 Force refreshing user data');
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
      print('✅ _refreshProfileData completed');
    } catch (e) {
      print('❌ Ошибка при обновлении данных профиля: $e');
    }
  }

  Future<void> _handleAvatarPicked(File photo) async {
    setState(() {
      _isLoading = true;
      _temporaryAvatar = photo;
    });

    try {
      final profileService = ref.read(promenadeProfileProvider);
      await profileService.uploadAvatar(photo);

      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_updated'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      setState(() {
        _temporaryAvatar = null;
      });
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_error'.tr(),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAvatarRemoved() async {
    setState(() {
      _isLoading = true;
      _temporaryAvatar = null;
    });

    try {
      final profileService = ref.read(promenadeProfileProvider);
      await profileService.removeAvatar();

      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_removed'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_error'.tr(),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logPersonalInfoClick() {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'personal_info_click',
      eventProperties: {
        'source': 'profile',
        'Platform': platform,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building ProfilePage widget');
    final userAsync = ref.watch(userProvider);
    final ticketsAsync = ref.watch(userTicketsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    print('📊 User data state: ${userAsync.toString()}');
    print('🎫 Tickets state: ${ticketsAsync.toString()}');
    print('⚙️ Settings state: ${settingsAsync.toString()}');
    print('🔒 Is checking auth: $_isCheckingAuth');

    // Показываем индикатор загрузки во время проверки авторизации
    if (_isCheckingAuth) {
      print('🔄 Showing skeleton loader - checking auth');
      return _buildSkeletonLoader();
    }

    return userAsync.when(
      loading: () {
        print('🔄 Showing skeleton loader - loading user data');
        return _buildSkeletonLoader();
      },
      error: (error, stack) {
        print('❌ Error in user data: $error');
        print('📚 Stack trace: $stack');

        // Проверяем тип ошибки более детально
        final errorStr = error.toString().toLowerCase();
        if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
          print('🔑 Unauthorized error detected, redirecting to login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.push('/login');
          });
          return const SizedBox.shrink();
        }

        print('⚠️ Showing error screen');
        return Scaffold(
          body: Container(
            color: AppColors.primary,
            child: SafeArea(
              child: Stack(
                children: [
                  Container(
                    color: AppColors.white,
                    margin: const EdgeInsets.only(top: 64),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'profile.load_error'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              print('🔄 Retrying profile load');
                              _checkAuthAndLoadProfile();
                            },
                            child: Text('common.refresh'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomHeader(
                    title: 'profile.mall_title'.tr(),
                    type: HeaderType.close,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (userData) {
        print('✅ Received user data: $userData');
        return Scaffold(
          body: Container(
            color: AppColors.primary,
            child: SafeArea(
              child: Stack(
                children: [
                  Container(
                    color: AppColors.white,
                    margin: const EdgeInsets.only(top: 64),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height -
                              64, // 64 это высота хедера
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Profile Info Section
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 30),
                                child: Row(
                                  children: [
                                    AvatarEditWidget(
                                      avatarUrl: userData.avatarUrl,
                                      temporaryImage: _temporaryAvatar,
                                      onAvatarPicked: _handleAvatarPicked,
                                      onAvatarRemoved: _handleAvatarRemoved,
                                      isLoading: _isLoading,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userData.firstName != null &&
                                                    userData.lastName != null
                                                ? '${userData.firstName} ${userData.lastName}'
                                                : userData.maskedPhone,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (userData.firstName != null &&
                                              userData.lastName != null)
                                            Text(
                                              userData.maskedPhone,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Menu Items
                              _buildMenuItem(
                                'profile.personal_info'.tr(),
                                Icons.chevron_right,
                                backgroundColor: Colors.grey[200],
                                onTap: () async {
                                  _logPersonalInfoClick();
                                  // Navigate and wait for result
                                  final result = await context.pushNamed(
                                    'mall_edit',
                                    pathParameters: {
                                      'id': widget.mallId.toString()
                                    },
                                  );

                                  // After returning, refresh the data
                                  if (mounted) {
                                    await _refreshProfileData();

                                    // Clear image cache for the avatar
                                    if (userData.avatarUrl != null) {
                                      imageCache.evict(
                                          NetworkImage(userData.avatarUrl!));
                                    }

                                    // Force rebuild
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(height: 8),

                              // Show tickets menu item if tickets are available
                              ticketsAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (tickets) {
                                  if (tickets.isNotEmpty) {
                                    return Column(
                                      children: [
                                        _buildMenuItem(
                                          'profile.coupons'.tr(),
                                          Icons.chevron_right,
                                          backgroundColor: Colors.grey[200],
                                          onTap: () {
                                            context.pushNamed(
                                              'tickets',
                                              pathParameters: {
                                                'id': widget.mallId.toString()
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),

                              _buildMenuItem(
                                'profile.contact_us'.tr(),
                                Icons.chevron_right,
                                backgroundColor: Colors.grey[200],
                                onTap: () {
                                  settingsAsync.whenData((settings) async {
                                    try {
                                      // Декодируем URL и заменяем закодированные символы
                                      final decodedUrl = Uri.decodeFull(
                                              settings.whatsappLinkAinaMall)
                                          .replaceAll('%2B', '+')
                                          .replaceAll('%20', ' ');

                                      // Пробуем сначала открыть через whatsapp://
                                      final whatsappUri =
                                          Uri.parse(decodedUrl.replaceAll(
                                        'https://api.whatsapp.com/send',
                                        'whatsapp://send',
                                      ));

                                      bool launched = false;
                                      try {
                                        launched = await launchUrl(
                                          whatsappUri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (_) {
                                        launched = false;
                                      }

                                      // Если не получилось открыть через whatsapp://, пробуем через https://
                                      if (!launched) {
                                        final httpUri = Uri.parse(decodedUrl);
                                        launched = await launchUrl(
                                          httpUri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }

                                      if (!launched && context.mounted) {
                                        BaseSnackBar.show(
                                          context,
                                          message:
                                              'communication.modal.whatsapp.error'
                                                  .tr(),
                                          type: SnackBarType.error,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        BaseSnackBar.show(
                                          context,
                                          message:
                                              'communication.modal.whatsapp.error'
                                                  .tr(),
                                          type: SnackBarType.error,
                                        );
                                      }
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 8),

                              _buildMenuItem(
                                'profile.about_app'.tr(),
                                Icons.chevron_right,
                                backgroundColor: Colors.grey[200],
                                onTap: () {
                                  context.pushNamed('about');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  CustomHeader(
                    title: 'profile.mall_title'.tr(),
                    type: HeaderType.close,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 64),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 64,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Profile Info Section Skeleton
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 30),
                            child: Row(
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          height: 20,
                                          width: 150,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
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
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Menu Items Skeleton
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: List.generate(
                                3, // Number of menu items
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CustomHeader(
                title: 'profile.mall_title'.tr(),
                type: HeaderType.close,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData? trailingIcon, {
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  SvgPicture.asset(
                    'lib/core/assets/icons/chevron-right.svg',
                    width: 24,
                    height: 24,
                    color: AppColors.almostBlack,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
