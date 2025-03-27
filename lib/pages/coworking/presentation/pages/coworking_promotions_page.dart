import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/widgets/promotions_block.dart';
import 'package:aina_flutter/widgets/events_block.dart';
import 'package:aina_flutter/shared/types/card_type.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/app/providers/requests/events_provider.dart';

class CoworkingPromotionsPage extends ConsumerStatefulWidget {
  final int coworkingId;
  final Map<String, dynamic>? extra;

  const CoworkingPromotionsPage({
    super.key,
    required this.coworkingId,
    this.extra,
  });

  @override
  ConsumerState<CoworkingPromotionsPage> createState() =>
      _CoworkingPromotionsPageState();
}

class _CoworkingPromotionsPageState
    extends ConsumerState<CoworkingPromotionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTabIndex = (widget.extra?['initialTabIndex'] as int?) ?? 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTabIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      await ref
          .read(eventsProvider.notifier)
          .fetchEvents(context, forceRefresh: true);
    } catch (e) {
      debugPrint(
          '❌ Ошибка при загрузке событий на странице CoworkingPromotionsPage: $e');
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
        final coworking = (buildings['coworking'] ?? [])
            .firstWhere((building) => building.id == widget.coworkingId);

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Column(
              children: [
                CustomHeader(
                  title:
                      'coworking.promotions_title'.tr(args: [coworking.name]),
                  type: HeaderType.pop,
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
                            mallId: widget.coworkingId.toString(),
                            onViewAllTap: () {},
                            showTitle: false,
                            showViewAll: false,
                            showDivider: false,
                            cardType: PromotionCardType.full,
                            showGradient: true,
                            emptyBuilder: (context) => Text(
                              'coworking.no_active_promotions'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Center(
                          child: EventsBlock(
                            mallId: widget.coworkingId.toString(),
                            onViewAllTap: () {},
                            showTitle: false,
                            showViewAll: false,
                            showDivider: false,
                            cardType: PromotionCardType.full,
                            showGradient: true,
                            emptyBuilder: (context) => Text(
                              'events.no_active_events'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                              textAlign: TextAlign.center,
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
    final is500Error = error.toString().contains('500') ||
        error.toString().contains('Internal Server Error');

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'promotions.title'.tr(),
              type: HeaderType.pop,
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
              type: HeaderType.pop,
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
