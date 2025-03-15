import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/promotions_provider.dart';
import 'package:aina_flutter/core/providers/requests/events_provider.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/widgets/events_block.dart';
import 'package:aina_flutter/core/types/promotion.dart';

class HomePromotionsPage extends ConsumerStatefulWidget {
  const HomePromotionsPage({super.key});

  @override
  ConsumerState<HomePromotionsPage> createState() => _HomePromotionsPageState();
}

class _HomePromotionsPageState extends ConsumerState<HomePromotionsPage>
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
      print('🔄 Загрузка акций и событий на странице HomePromotionsPage');
      await Future.wait([
        ref
            .read(promotionsProvider.notifier)
            .fetchPromotions(context, forceRefresh: true),
        ref
            .read(eventsProvider.notifier)
            .fetchEvents(context, forceRefresh: true),
      ]);
      print(
          '✅ Акции и события успешно загружены на странице HomePromotionsPage');
    } catch (e) {
      print('❌ Ошибка при загрузке данных на странице HomePromotionsPage: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
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
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Container(
                          color: AppColors.appBg,
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.only(top: 28, bottom: 28),
                              child: PromotionsBlock(
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
                          ),
                        ),
                        Container(
                          color: AppColors.appBg,
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.only(top: 28, bottom: 28),
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

                                      final is500Error =
                                          error.toString().contains('500') ||
                                              error.toString().contains(
                                                  'Internal Server Error');

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
                                    data: (List<Promotion> events) {
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

                                      return EventsBlock(
                                        onViewAllTap: () {},
                                        showTitle: false,
                                        showViewAll: false,
                                        showDivider: false,
                                        cardType: PromotionCardType.full,
                                        showGradient: true,
                                        events: events,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            CustomHeader(
              title: 'promotions.title'.tr(),
              type: HeaderType.close,
            ),
          ],
        ),
      ),
    );
  }
}
