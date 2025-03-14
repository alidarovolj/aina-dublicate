import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/mall_promotions_provider.dart';
import 'package:aina_flutter/core/providers/requests/promotions_provider.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PromotionsBlock extends ConsumerWidget {
  final String? mallId;
  final VoidCallback? onViewAllTap;
  final bool showTitle;
  final bool showViewAll;
  final bool showDivider;
  final PromotionCardType cardType;
  final bool showGradient;
  final Widget Function(BuildContext)? emptyBuilder;
  final int? maxElements;
  final bool sortByQr;
  final bool showArrow;

  const PromotionsBlock({
    super.key,
    this.mallId,
    this.onViewAllTap,
    this.showTitle = true,
    this.showViewAll = true,
    this.showDivider = true,
    this.cardType = PromotionCardType.medium,
    this.showGradient = false,
    this.emptyBuilder,
    this.maxElements,
    this.sortByQr = false,
    this.showArrow = false,
  });

  List<dynamic> _sortPromotions(List<dynamic> promotions) {
    if (!sortByQr) return promotions;

    return List<dynamic>.from(promotions)
      ..sort((a, b) {
        if (a.isQr == b.isQr) return 0;
        return a.isQr ? -1 : 1;
      });
  }

  void _logPromotionClick(BuildContext context, dynamic promotion) {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'promotion_click',
      eventProperties: {
        'Platform': platform,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = mallId != null
        ? ref.watch(mallPromotionsProvider(mallId!))
        : ref.watch(promotionsProvider);

    // print('PromotionsBlock mallId: $mallId');

    return promotionsAsync.when(
      loading: () => _buildSkeletonLoader(cardType),
      error: (error, stack) {
        // print('Error in PromotionsBlock: $error');
        return _buildErrorWidget(context, ref, error);
      },
      data: (promotions) {
        // print('Received promotions: ${promotions.length}');
        if (promotions.isEmpty) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }

        final sortedPromotions = _sortPromotions(promotions);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle || showViewAll)
              Padding(
                padding: const EdgeInsets.only(
                    left: AppLength.xs,
                    bottom: AppLength.xs,
                    top: AppLength.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showTitle)
                      Text(
                        'promotions.title'.tr(),
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    if (showViewAll && onViewAllTap != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onViewAllTap,
                        child: Row(
                          children: [
                            Text(
                              'promotions.view_all'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            SvgPicture.asset(
                              'lib/core/assets/icons/chevron-right.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textDarkGrey,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (cardType == PromotionCardType.medium)
              _buildMediumCardList(context, sortedPromotions)
            else if (cardType == PromotionCardType.small)
              _buildSmallCardGrid(context, sortedPromotions)
            else
              _buildFullCardList(context, sortedPromotions),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.symmetric(
                    vertical: AppLength.xs, horizontal: AppLength.xs),
                child: Divider(
                  color: Colors.black12,
                  thickness: 1,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
    // Определяем высоту в зависимости от типа карточки
    double height = cardType == PromotionCardType.medium
        ? 201
        : cardType == PromotionCardType.small
            ? 94
            : 200;

    // Проверяем, содержит ли ошибка код 500
    final is500Error = error.toString().contains('500') ||
        error.toString().contains('Internal Server Error');

    print('❌ Ошибка при загрузке промоакций: $error');

    return ErrorRefreshWidget(
      height: height,
      onRefresh: () {
        print('🔄 Обновление промоакций...');
        Future.microtask(() async {
          try {
            if (mallId != null) {
              ref.refresh(mallPromotionsProvider(mallId!));
            } else {
              await ref
                  .read(promotionsProvider.notifier)
                  .fetchPromotions(context, forceRefresh: true);
            }
            print('✅ Запрос на обновление промоакций отправлен');
          } catch (e) {
            print('❌ Ошибка при обновлении промоакций: $e');
          }
        });
      },
      errorMessage: is500Error
          ? 'stories.error.server'.tr()
          : 'stories.error.loading'.tr(),
      refreshText: 'common.refresh'.tr(),
      icon: Icons.warning_amber_rounded,
      isCompact: cardType == PromotionCardType.small,
      isServerError: true,
    );
  }

  Widget _buildImageWithGradient(String imageUrl,
      {double height = 124, double borderRadius = 4.0}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: showGradient
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMediumCardList(BuildContext context, List<dynamic> promotions) {
    final limitedPromotions = maxElements != null
        ? promotions.take(maxElements!).toList()
        : promotions;

    return SizedBox(
      height: 201,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: limitedPromotions.length,
        itemBuilder: (context, index) {
          final promotion = limitedPromotions[index];
          return GestureDetector(
            onTap: () {
              _logPromotionClick(context, promotion);
              context.pushNamed(
                'promotion_details',
                pathParameters: {'id': promotion.id.toString()},
              );
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _buildImageWithGradient(promotion.previewImage.url),
                      if (showArrow)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: SvgPicture.asset(
                            'lib/core/assets/icons/linked-arrow.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promotion.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.formattedDateRange,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullCardList(BuildContext context, List<dynamic> promotions) {
    final limitedPromotions = maxElements != null
        ? promotions.take(maxElements!).toList()
        : promotions;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
      itemCount: limitedPromotions.length,
      itemBuilder: (context, index) {
        final promotion = limitedPromotions[index];
        return GestureDetector(
          onTap: () {
            _logPromotionClick(context, promotion);
            context.pushNamed(
              'promotion_details',
              pathParameters: {'id': promotion.id.toString()},
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                _buildImageWithGradient(
                  promotion.previewImage.url,
                  height: 200,
                  borderRadius: 8,
                ),
                if (showArrow)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SvgPicture.asset(
                      'lib/core/assets/icons/linked-arrow.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                // Positioned(
                //   top: 16,
                //   left: 16,
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: AppLength.xs,
                //       vertical: AppLength.four,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(4),
                //     ),
                //     child: const Text(
                //       'Moskva',
                //       style: TextStyle(
                //         fontSize: 14,
                //         color: AppColors.primary,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ),
                // ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        style: GoogleFonts.lora(
                          fontSize: 17,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.formattedDateRange,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallCardGrid(BuildContext context, List<dynamic> promotions) {
    final limitedPromotions = maxElements != null
        ? promotions.take(maxElements!).toList()
        : promotions;

    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = AppLength.xs * 2;
    const itemSpacing = 12.0;
    final totalSpacing = itemSpacing * (limitedPromotions.length - 1);
    final availableWidth = screenWidth - horizontalPadding - totalSpacing;
    final itemWidth = availableWidth / limitedPromotions.length;

    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: limitedPromotions.length,
        itemBuilder: (context, index) {
          final promotion = limitedPromotions[index];
          return GestureDetector(
            onTap: () {
              _logPromotionClick(context, promotion);
              context.pushNamed(
                'promotion_details',
                pathParameters: {'id': promotion.id.toString()},
              );
            },
            child: Stack(
              children: [
                Container(
                  width: itemWidth,
                  margin: EdgeInsets.only(
                      right: index != limitedPromotions.length - 1
                          ? itemSpacing
                          : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(promotion.previewImage.url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (showArrow)
                  Positioned(
                    top: 8,
                    right: index != limitedPromotions.length - 1
                        ? itemSpacing + 8
                        : 8,
                    child: SvgPicture.asset(
                      'lib/core/assets/icons/linked-arrow.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader(PromotionCardType type) {
    if (type == PromotionCardType.medium) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle || showViewAll)
            Padding(
              padding: const EdgeInsets.all(AppLength.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showTitle)
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            height: 201,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[100]!,
                  highlightColor: Colors.grey[300]!,
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 124,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (type == PromotionCardType.small) {
      return SizedBox(
        height: 94,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.grey[300]!,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Column(
        children: List.generate(2, (index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              height: 200,
              margin: const EdgeInsets.symmetric(
                horizontal: AppLength.xs,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      );
    }
  }
}
