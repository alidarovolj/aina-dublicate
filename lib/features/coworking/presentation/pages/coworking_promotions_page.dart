import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';

class CoworkingPromotionsPage extends ConsumerWidget {
  final int coworkingId;

  const CoworkingPromotionsPage({
    super.key,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return buildingsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Stack(
            children: [
              _buildSkeletonLoader(),
              const CustomHeader(
                title: '',
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: Text('coworking.error'.tr(args: [error.toString()])),
      ),
      data: (buildings) {
        final coworking = (buildings['coworking'] ?? [])
            .firstWhere((building) => building.id == coworkingId);

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.appBg,
                  margin: const EdgeInsets.only(top: 64),
                  padding: const EdgeInsets.only(top: 28),
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 64,
                  ),
                  child: SingleChildScrollView(
                    child: PromotionsBlock(
                      mallId: coworkingId.toString(),
                      showTitle: false,
                      showViewAll: false,
                      showDivider: false,
                      cardType: PromotionCardType.full,
                      emptyBuilder: (context) => Center(
                        child: Text(
                          'coworking.no_active_promotions'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textDarkGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                CustomHeader(
                  title:
                      'coworking.promotions_title'.tr(args: [coworking.name]),
                  type: HeaderType.pop,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      color: AppColors.appBg,
      margin: const EdgeInsets.only(top: 64),
      padding: const EdgeInsets.only(top: 28),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: 5, // Show 5 promotion skeletons
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.grey[300]!,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image area
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    // Text content area
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 200,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
