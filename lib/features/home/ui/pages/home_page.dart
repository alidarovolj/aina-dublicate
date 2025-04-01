import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/shared/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/blocks/stories_list.dart';
import 'package:aina_flutter/shared/ui/widgets/base_slider.dart';
import 'package:aina_flutter/shared/ui/blocks/upper_header.dart';
import 'package:aina_flutter/app/providers/requests/banners_provider.dart';
import 'package:aina_flutter/shared/ui/blocks/buildings_list.dart';
import 'package:aina_flutter/app/providers/requests/promotions_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/utils/button_navigation_handler.dart';
import 'package:aina_flutter/shared/types/button_config.dart';
import 'package:aina_flutter/shared/navigation/index.dart';
import 'package:aina_flutter/app/providers/requests/settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/blocks/home_promotions_block.dart';
import 'package:aina_flutter/shared/ui/blocks/error_refresh_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  // Добавляем ключ для HomePromotionsBlock
  final GlobalKey _promotionsKey = GlobalKey();
  int _rebuildCounter = 0;

  // Добавляем переменную для отслеживания времени последнего обновления
  DateTime _lastUpdateTime = DateTime.now();

  // Флаг для отслеживания, был ли выполнен первоначальный запрос данных
  bool _initialDataFetched = false;

  @override
  void initState() {
    super.initState();
    _initialDataFetched = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchData(forceRefresh: true);
      }
    });
  }

  // Метод для загрузки всех данных
  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (!mounted || _initialDataFetched && !forceRefresh) return;

    try {
      if (!mounted) return;

      _initialDataFetched = true;

      // Обновляем настройки
      if (mounted) {
        try {
          ref.refresh(settingsProvider);
        } catch (e) {
          debugPrint('❌ Ошибка при обновлении настроек: $e');
        }
      }

      // Обновляем акции
      if (mounted) {
        try {
          ref.invalidate(promotionsProvider);
          await ref
              .read(promotionsProvider.notifier)
              .fetchPromotions(context, forceRefresh: forceRefresh);
        } catch (e) {
          debugPrint('❌ Ошибка при загрузке акций: $e');
        }
      }

      // Обновляем баннеры только если forceRefresh = true
      if (mounted && forceRefresh) {
        try {
          ref.invalidate(bannersProvider);
          await ref
              .read(bannersProvider.notifier)
              .fetchBanners(forceRefresh: true);
        } catch (e) {
          debugPrint('❌ Ошибка при загрузке баннеров: $e');
        }
      }

      // Проверяем аутентификацию и загружаем профиль
      if (mounted) {
        try {
          await _checkAuthAndFetchProfile();
        } catch (e) {
          debugPrint('❌ Ошибка при проверке аутентификации: $e');
        }
      }

      // Обновляем время последнего обновления и счетчик для пересоздания виджетов
      if (mounted) {
        setState(() {
          _rebuildCounter++;
          _lastUpdateTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Ошибка при загрузке данных: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    // Обновляем только если прошло достаточно времени с последнего обновления
    if (DateTime.now().difference(_lastUpdateTime) >
        const Duration(seconds: 5)) {
      Future.microtask(() async {
        if (!mounted) return;
        await _fetchData(forceRefresh: true);
      });
    }
  }

  Future<void> _checkAuthAndFetchProfile() async {
    if (!mounted) return;

    try {
      final authState = ref.read(authProvider);
      if (!mounted) return;

      if (authState.isAuthenticated && authState.token != null) {
        try {
          final response = await ApiClient().dio.get('/api/promenade/profile');
          if (!mounted) return;

          if (response.data['success'] == true &&
              response.data['data'] != null) {
            try {
              if (!mounted) return;
              final authNotifier = ref.read(authProvider.notifier);
              if (!mounted) return;
              authNotifier.updateUserData(response.data['data']);
            } catch (e) {
              debugPrint('❌ Ошибка при обновлении данных пользователя: $e');
            }
          }
        } catch (e) {
          debugPrint('❌ Ошибка при загрузке профиля: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке аутентификации: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Container(
              color: AppColors.appBg,
              // Игнорируем уведомления о прокрутке, связанные с оттягиванием вниз
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (OverscrollIndicatorNotification notification) {
                  // Отменяем индикатор overscroll (эффект свечения при оттягивании)
                  notification.disallowIndicator();
                  return true;
                },
                child: CustomScrollView(
                  // Используем стандартную ClampingScrollPhysics, которая не показывает эффект overscroll
                  // но позволяет нормально прокручивать контент
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: UpperHeader(),
                    ),
                    const SliverToBoxAdapter(
                      child: StoryList(),
                    ),
                    SliverToBoxAdapter(
                      child: bannersAsync.when(
                        loading: () => RepaintBoundary(
                          child: Shimmer.fromColors(
                            period: const Duration(milliseconds: 1500),
                            baseColor: Colors.grey[100]!,
                            highlightColor: Colors.grey[300]!,
                            child: Container(
                              height: 200,
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppLength.xs,
                                vertical: AppLength.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        error: (error, stack) {
                          final is500Error = error.toString().contains('500') ||
                              error
                                  .toString()
                                  .contains('Internal Server Error');

                          return ErrorRefreshWidget(
                            height: 200,
                            onRefresh: () {
                              if (!mounted) return;
                              ref
                                  .read(bannersProvider.notifier)
                                  .fetchBanners(forceRefresh: true);
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
                        data: (banners) {
                          if (banners.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return CarouselWithIndicator(
                            slideList: banners,
                            showIndicators: true,
                            onSlideClick: (slide) {
                              if (!mounted) return;
                              if (slide.button == null) return;

                              final button = slide.button!;
                              ButtonNavigationHandler.handleNavigation(
                                context,
                                ref,
                                ButtonConfig(
                                  label: button.label,
                                  color: button.color,
                                  isInternal: button.isInternal,
                                  link: button.link,
                                  internal: button.isInternal == true &&
                                          button.internal != null
                                      ? ButtonInternal(
                                          model: button.internal!.model,
                                          id: button.internal!.id ?? 0,
                                          buildingType:
                                              button.internal!.buildingType ??
                                                  '',
                                          isAuthRequired:
                                              button.internal!.isAuthRequired,
                                        )
                                      : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: BuildingsList(),
                    ),
                    // Используем HomePromotionsBlock с ключом для пересоздания виджета
                    SliverToBoxAdapter(
                      // Используем более уникальный ключ, включающий время последнего обновления
                      key: ValueKey(
                          'promotions_block_${_rebuildCounter}_${_lastUpdateTime.millisecondsSinceEpoch}'),
                      child: Builder(builder: (context) {
                        // Используем Builder для создания нового контекста
                        return HomePromotionsBlock(
                          // Используем уникальный ключ для самого виджета
                          key: Key(
                              'promotions_key_${_rebuildCounter}_${_lastUpdateTime.millisecondsSinceEpoch}'),
                          cardType: PromotionCardType.small,
                          showArrow: true,
                          showDivider: false,
                          sortByQr: true,
                          maxElements: 2,
                          onViewAllTap: () {
                            context.pushNamed('promotions');
                          },
                        );
                      }),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: AppLength.xxxl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
