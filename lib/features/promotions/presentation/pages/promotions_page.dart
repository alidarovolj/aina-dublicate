import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/widgets/events_block.dart';

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
          body: Container(
            color: AppColors.primary,
            child: SafeArea(
              child: Stack(
                children: [
                  Container(
                    color: AppColors.white,
                    margin: const EdgeInsets.only(top: 64),
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                padding: const EdgeInsets.all(4),
                                tabAlignment: TabAlignment.fill,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: const [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Tab(text: 'Акции'),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Tab(text: 'Мероприятия'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverFillRemaining(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              PromotionsBlock(
                                mallId: widget.mallId.toString(),
                                onViewAllTap: () {},
                                showTitle: false,
                                showViewAll: false,
                                showDivider: false,
                                cardType: PromotionCardType.full,
                                showGradient: true,
                              ),
                              EventsBlock(
                                mallId: widget.mallId.toString(),
                                onViewAllTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomHeader(
                    title: mall.name,
                    onClose: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
