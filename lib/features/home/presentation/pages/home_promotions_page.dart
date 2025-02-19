import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/events_block.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';

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
        child: Column(
          children: [
            CustomHeader(
              title: 'promotions.title'.tr(),
              type: HeaderType.close,
            ),
            Container(
              color: AppColors.appBg,
              padding: const EdgeInsets.all(12.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                    SingleChildScrollView(
                      child: PromotionsBlock(
                        onViewAllTap: () {},
                        showTitle: false,
                        showViewAll: false,
                        showDivider: false,
                        cardType: PromotionCardType.full,
                        showGradient: true,
                        emptyBuilder: (context) => Center(
                          child: Text(
                            'promotions.no_active_promotions'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textDarkGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      child: EventsBlock(
                        mallId: "0",
                        onViewAllTap: () {},
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
  }
}
