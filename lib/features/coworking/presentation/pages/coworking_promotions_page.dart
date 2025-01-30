import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:easy_localization/easy_localization.dart';

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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
}
