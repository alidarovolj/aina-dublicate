import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/providers/requests/events_provider.dart';

class PromotionsPage extends ConsumerStatefulWidget {
  final int mallId;

  const PromotionsPage({
    super.key,
    required this.mallId,
  });

  @override
  ConsumerState<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends ConsumerState<PromotionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      print('🔄 Загрузка событий на странице PromotionsPage');
      await ref
          .read(eventsProvider.notifier)
          .fetchEvents(context, forceRefresh: true);
      print('✅ События успешно загружены на странице PromotionsPage');
    } catch (e) {
      print('❌ Ошибка при загрузке событий на странице PromotionsPage: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return buildingsAsync.when(
      data: (buildings) {
        final mall = (buildings['mall'] ?? [])
            .firstWhere((building) => building.id == widget.mallId);

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Column(
              children: [
                CustomHeader(
                  title: 'promotions.title'.tr(),
                  type: HeaderType.close,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                    top: 12.0,
                    bottom: 12.0,
                  ),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                      tabAlignment: TabAlignment.fill,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        SizedBox(
                          width: double.infinity,
                          child: Tab(text: 'promotions.title'.tr()),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Tab(text: 'events.title'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.appBg,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Center(
                          child: PromotionsBlock(
                            mallId: widget.mallId.toString(),
                            onViewAllTap: () {},
                            showTitle: false,
                            showViewAll: false,
                            showDivider: false,
                            cardType: PromotionCardType.full,
                            showGradient: true,
                            emptyBuilder: (context) => Text(
                              'promotions.no_active_promotions'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 28, bottom: 28),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final eventsAsync = ref.watch(eventsProvider);

                                return eventsAsync.when(
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (error, stack) {
                                    print(
                                        '❌ Ошибка при загрузке событий: $error');

                                    final is500Error = error
                                            .toString()
                                            .contains('500') ||
                                        error
                                            .toString()
                                            .contains('Internal Server Error');

                                    return ErrorRefreshWidget(
                                      onRefresh: () {
                                        print('🔄 Обновление событий...');
                                        Future.microtask(() async {
                                          try {
                                            ref
                                                .read(eventsProvider.notifier)
                                                .fetchEvents(context,
                                                    forceRefresh: true);
                                          } catch (e) {
                                            print(
                                                '❌ Ошибка при обновлении событий: $e');
                                          }
                                        });
                                      },
                                      errorMessage: is500Error
                                          ? 'stories.error.server'.tr()
                                          : 'stories.error.loading'.tr(),
                                      refreshText: 'common.refresh'.tr(),
                                      icon: Icons.warning_amber_rounded,
                                      isServerError: true,
                                    );
                                  },
                                  data: (events) {
                                    if (events.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'events.no_active_events'.tr(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: AppColors.textDarkGrey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }

                                    return PromotionsBlock(
                                      onViewAllTap: () {},
                                      showTitle: false,
                                      showViewAll: false,
                                      showDivider: false,
                                      cardType: PromotionCardType.full,
                                      showGradient: true,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildErrorWidget(Object error) {
    // Проверяем, содержит ли ошибка код 500
    final is500Error = error.toString().contains('500') ||
        error.toString().contains('Internal Server Error');

    print('❌ Ошибка при загрузке страницы промоакций: $error');

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'promotions.title'.tr(),
              type: HeaderType.close,
            ),
            Expanded(
              child: Container(
                color: AppColors.appBg,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: ErrorRefreshWidget(
                      onRefresh: () {
                        print('🔄 Обновление страницы промоакций...');
                        ref.refresh(buildingsProvider);
                      },
                      errorMessage: 'stories.error.loading'.tr(),
                      refreshText: 'common.refresh'.tr(),
                      icon: Icons.warning_amber_rounded,
                      isServerError: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'promotions.title'.tr(),
              type: HeaderType.close,
            ),
            // Tab bar skeleton
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            // Content skeleton
            Expanded(
              child: Container(
                color: AppColors.appBg,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
