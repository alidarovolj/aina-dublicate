import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/types/card_type.dart';

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
      error: (error, stack) => Center(child: Text('Error: $error')),
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
                    emptyBuilder: (context) => const Center(
                      child: Text(
                        'В данный момент нет акций',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textDarkGrey,
                        ),
                      ),
                    ),
                  ),
                ),
                CustomHeader(
                  title: 'Акции ${coworking.name}',
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
