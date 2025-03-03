import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';
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
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 28, bottom: 28),
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
                        Container(
                          color: AppColors.appBg,
                          child: Center(
                            child: Text(
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
