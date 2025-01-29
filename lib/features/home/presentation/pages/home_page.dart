import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/stories_list.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/widgets/upper_header.dart';
import 'package:aina_flutter/core/providers/requests/banners_provider.dart';
import 'package:aina_flutter/core/widgets/buildings_list.dart';
import 'package:aina_flutter/core/providers/requests/promotions_provider.dart';
import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final promotionsAsync = ref.watch(promotionsProvider);
    print('show token ${ref.read(authProvider).token}');

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Container(
            color: AppColors.appBg,
            child: CustomScrollView(
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
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                    data: (banners) => CarouselWithIndicator(
                      slideList: banners,
                      showIndicators: false,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: BuildingsList(),
                ),
                const SliverToBoxAdapter(
                  child: PromotionsBlock(
                      showTitle: true,
                      showViewAll: false,
                      showDivider: false,
                      cardType: PromotionCardType.small),
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
    );
  }
}
