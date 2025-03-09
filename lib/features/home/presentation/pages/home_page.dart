import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/stories_list.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/widgets/upper_header.dart';
import 'package:aina_flutter/core/providers/requests/banners_provider.dart';
import 'package:aina_flutter/core/widgets/buildings_list.dart';
import 'package:aina_flutter/core/providers/requests/promotions_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/utils/button_navigation_handler.dart';
import 'package:aina_flutter/core/types/button_config.dart';
import 'package:aina_flutter/core/router/route_observer.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:aina_flutter/core/widgets/home_promotions_block.dart';
import 'dart:convert';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/providers/requests/stories_provider.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchData(forceRefresh: true);
      }
    });
  }

  // Метод для загрузки всех данных
  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Устанавливаем флаг, что данные были загружены
    _initialDataFetched = true;

    try {
      // Инвалидируем провайдеры для обновления данных
      if (!mounted) return;
      print('🔄 Инвалидация провайдеров для обновления данных');

      // Обновляем настройки
      if (mounted) {
        try {
          ref.refresh(settingsProvider);
          print('✅ Настройки обновлены');
        } catch (e) {
          print('❌ Ошибка при обновлении настроек: $e');
        }
      }

      // Обновляем акции
      if (mounted) {
        try {
          // Инвалидируем провайдер акций
          ref.invalidate(promotionsProvider);
          print('✅ Провайдер акций инвалидирован');

          // Загружаем акции
          await ref
              .read(promotionsProvider.notifier)
              .fetchPromotions(context, forceRefresh: forceRefresh);
          print('✅ Акции загружены');
        } catch (e) {
          print('❌ Ошибка при загрузке акций: $e');
        }
      }

      // Обновляем баннеры
      if (mounted) {
        try {
          // Инвалидируем провайдер баннеров
          ref.invalidate(bannersProvider);
          print('✅ Провайдер баннеров инвалидирован');
        } catch (e) {
          print('❌ Ошибка при инвалидации провайдера баннеров: $e');
        }
      }

      // Проверяем аутентификацию и загружаем профиль
      if (mounted) {
        try {
          await _checkAuthAndFetchProfile();
        } catch (e) {
          print('❌ Ошибка при проверке аутентификации: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        print('❌ Ошибка при загрузке данных: $e');
      }
    }

    // Обновляем время последнего обновления и счетчик для пересоздания виджетов
    if (mounted) {
      setState(() {
        _rebuildCounter++;
        _lastUpdateTime = DateTime.now();
        print(
            '✅ Обновление завершено. Счетчик: $_rebuildCounter, Время: $_lastUpdateTime');
      });
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

  // Метод для обновления данных при возврате на страницу
  Future<void> _refreshDataOnReturn() async {
    if (!mounted) return;

    try {
      // Инвалидируем провайдеры для обновления данных
      if (!mounted) return;

      // Инвалидируем провайдер акций
      try {
        ref.invalidate(promotionsProvider);
        print('✅ Провайдер акций инвалидирован при возврате на страницу');
      } catch (e) {
        print('❌ Ошибка при инвалидации провайдера акций: $e');
      }

      // Инвалидируем провайдер баннеров
      if (!mounted) return;
      try {
        ref.invalidate(bannersProvider);
        print('✅ Провайдер баннеров инвалидирован при возврате на страницу');
      } catch (e) {
        print('❌ Ошибка при инвалидации провайдера баннеров: $e');
      }

      // Увеличиваем счетчик для создания нового ключа и обновляем время
      if (!mounted) return;
      setState(() {
        _rebuildCounter++;
        _lastUpdateTime = DateTime.now();
      });

      // Загружаем данные
      if (!mounted) return;
      await _fetchData(forceRefresh: true);

      // Добавляем еще одну задержку для гарантированного обновления после загрузки данных
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          // Обновляем только счетчик, чтобы пересоздать виджет
          _rebuildCounter++;
        });
      });
    } catch (e) {
      if (mounted) {
        print('❌ Ошибка при обновлении данных при возврате на страницу: $e');
      }
    }
  }

  @override
  void didPopNext() {
    if (!mounted) return;

    print('🔄 Возврат на главную страницу через didPopNext');
    // Запускаем обновление данных в отдельном Future, чтобы не блокировать UI
    Future.microtask(() async {
      if (!mounted) return;
      await _refreshDataOnReturn();
    });
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
              print('✅ Профиль пользователя обновлен');
            } catch (e) {
              print('❌ Ошибка при обновлении данных пользователя: $e');
            }
          }
        } catch (e) {
          print('❌ Ошибка при загрузке профиля: $e');
        }
      }
    } catch (e) {
      print('❌ Ошибка при проверке аутентификации: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);

    // Если данные еще не были загружены, загружаем их
    if (!_initialDataFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _fetchData(forceRefresh: true);
      });
    }

    return PopScope(
      // Обрабатываем системную кнопку "Назад" и свайп
      onPopInvoked: (didPop) {
        if (didPop && mounted) {
          // Если мы действительно вернулись на эту страницу
          print(
              '🔄 Возврат на главную страницу через системную кнопку или свайп');
          // Запускаем обновление данных в отдельном Future, чтобы не блокировать UI
          Future.microtask(() async {
            if (!mounted) return;
            await _refreshDataOnReturn();
          });
        }
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
                        loading: () => Shimmer.fromColors(
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
                        error: (error, stack) {
                          print('❌ Ошибка при загрузке баннеров: $error');
                          return Container(
                            height: 200,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppLength.xs,
                              vertical: AppLength.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: ErrorRefreshWidget(
                              onRefresh: () {
                                if (!mounted) return;
                                // Используем Future.microtask для асинхронного обновления
                                Future.microtask(() {
                                  if (!mounted) return;
                                  try {
                                    ref.invalidate(bannersProvider);
                                  } catch (e) {
                                    print(
                                        '❌ Ошибка при обновлении баннеров: $e');
                                  }
                                });
                              },
                              errorMessage: 'stories.error.loading'.tr(),
                              isCompact: true,
                              isServerError: true,
                              backgroundColor: Colors.transparent,
                              textColor: Colors.red.shade900,
                              errorColor: Colors.red,
                              icon: Icons.warning_amber_rounded,
                            ),
                          );
                        },
                        data: (banners) {
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
