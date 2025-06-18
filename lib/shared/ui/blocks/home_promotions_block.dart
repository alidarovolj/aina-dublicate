import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/mall_promotions_provider.dart';
import 'package:aina_flutter/app/providers/requests/promotions_provider.dart';
import 'package:aina_flutter/shared/types/card_type.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/shared/ui/blocks/error_refresh_widget.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class HomePromotionsBlock extends ConsumerWidget {
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

  const HomePromotionsBlock({
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

  void _logPromotionClick(BuildContext context, dynamic promotion) {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'promotion_click',
      eventProperties: {
        'Platform': platform,
      },
    );
  }

  List<dynamic> _sortPromotions(List<dynamic> promotions) {
    if (!sortByQr) return promotions;

    return List<dynamic>.from(promotions)
      ..sort((a, b) {
        if (a.isQr == b.isQr) return 0;
        return a.isQr ? -1 : 1;
      });
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

  Widget _buildArchiveOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.black.withOpacity(0.7),
        ),
        child: const Center(
          child: Text(
            'В архиве',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                _logPromotionClick(context, promotion);
                Future.delayed(Duration.zero, () {
                  if (context.mounted) {
                    context.pushNamed(
                      'promotion_details',
                      pathParameters: {'id': promotion.id.toString()},
                    );
                  }
                });
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
                        if (!promotion.isActive) _buildArchiveOverlay(),
                        if (showArrow)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: SvgPicture.asset(
                              'lib/app/assets/icons/linked-arrow.svg',
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
                if (!promotion.isActive) _buildArchiveOverlay(),
                if (showArrow)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SvgPicture.asset(
                      'lib/app/assets/icons/linked-arrow.svg',
                      width: 24,
                      height: 24,
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
    if (promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    final limitedPromotions = maxElements != null
        ? promotions.take(maxElements!).toList()
        : promotions;

    if (limitedPromotions.isEmpty) {
      return const SizedBox.shrink();
    }

    const double itemWidth = 160.0;
    const double itemHeight = 94.0;
    const double itemSpacing = 12.0;

    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: limitedPromotions.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: itemSpacing),
        itemBuilder: (context, index) {
          if (index >= limitedPromotions.length) {
            return const SizedBox.shrink();
          }

          final promotion = limitedPromotions[index];
          final imageUrl = promotion.previewImage?.url ?? '';

          if (imageUrl.isEmpty) {
            return Container(
              width: itemWidth,
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported, color: Colors.white),
              ),
            );
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                _logPromotionClick(context, promotion);
                Future.delayed(Duration.zero, () {
                  if (context.mounted) {
                    context.pushNamed(
                      'promotion_details',
                      pathParameters: {'id': promotion.id.toString()},
                    );
                  }
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: itemWidth,
                        height: itemHeight,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: itemWidth,
                            height: itemHeight,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error_outline,
                                  color: Colors.white),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: itemWidth,
                            height: itemHeight,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      if (!promotion.isActive) _buildArchiveOverlay(),
                      if (showArrow)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: SvgPicture.asset(
                            'lib/app/assets/icons/linked-arrow.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader(PromotionCardType type) {
    if (type == PromotionCardType.medium) {
      return Column(
        children: [
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
      const double itemWidth = 160.0;
      const double itemHeight = 94.0;
      const double itemSpacing = 12.0;

      return SizedBox(
        height: itemHeight,
        width: double.infinity,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
          itemCount: 2,
          separatorBuilder: (context, index) =>
              const SizedBox(width: itemSpacing),
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.grey[300]!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: itemWidth,
                  height: itemHeight,
                  color: Colors.grey[300],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = mallId != null
        ? ref.watch(mallPromotionsProvider(mallId!))
        : ref.watch(promotionsProvider);

    if (promotionsAsync.isLoading) {
      return _buildSkeletonLoader(cardType);
    }

    if (promotionsAsync.hasError) {
      double height = cardType == PromotionCardType.medium
          ? 201
          : cardType == PromotionCardType.small
              ? 94
              : 200;

      return ErrorRefreshWidget(
        height: height,
        onRefresh: () {
          Future.microtask(() {
            try {
              if (mallId != null) {
                ref.refresh(mallPromotionsProvider(mallId!));
              } else {
                ref.refresh(promotionsProvider);
              }
            } catch (e) {
              debugPrint('❌ Ошибка при обновлении промоакций: $e');
            }
          });
        },
        errorMessage: 'stories.error.loading'.tr(),
        refreshText: 'common.refresh'.tr(),
        icon: Icons.warning_amber_rounded,
        isCompact: cardType == PromotionCardType.small,
        isServerError: true,
      );
    }

    final promotions = promotionsAsync.value ?? [];
    if (promotions.isEmpty) {
      return emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    // Сортируем промоакции: активные первыми
    final sortedPromotions = _sortPromotions(promotions)
      ..sort((a, b) {
        // Сначала сортируем по статусу активности (активные первыми)
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return 0;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle || showViewAll)
          Padding(
            padding: const EdgeInsets.only(
                left: AppLength.xs, bottom: AppLength.xs, top: AppLength.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showTitle)
                  Row(
                    children: [
                      Text(
                        'promotions.title'.tr(),
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      )
                    ],
                  ),
                if (showViewAll && onViewAllTap != null)
                  TextButton(
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
                          'lib/app/assets/icons/chevron-right.svg',
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
  }
}
