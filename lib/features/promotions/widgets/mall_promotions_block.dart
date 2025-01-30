import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/mall_promotions_provider.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class MallPromotionsBlock extends ConsumerWidget {
  final String mallId;
  final VoidCallback? onViewAllTap;
  final bool showTitle;
  final bool showViewAll;
  final bool showDivider;
  final PromotionCardType cardType;
  final bool showGradient;
  final Widget Function(BuildContext)? emptyBuilder;

  const MallPromotionsBlock({
    super.key,
    required this.mallId,
    this.onViewAllTap,
    this.showTitle = true,
    this.showViewAll = true,
    this.showDivider = true,
    this.cardType = PromotionCardType.medium,
    this.showGradient = false,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(mallPromotionsProvider(mallId));

    // print('MallPromotionsBlock mallId: $mallId');

    return promotionsAsync.when(
      loading: () => _buildSkeletonLoader(cardType),
      error: (error, stack) {
        // print('Error in MallPromotionsBlock: $error');
        return const SizedBox.shrink();
      },
      data: (promotions) {
        // print('Received mall promotions: ${promotions.length}');
        if (promotions.isEmpty) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }

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
                      Text(
                        'promotions.title'.tr(),
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (showViewAll && onViewAllTap != null)
                      TextButton(
                        onPressed: onViewAllTap,
                        child: Row(
                          children: [
                            Text(
                              'promotions.view_all'.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (cardType == PromotionCardType.medium)
              _buildMediumCardList(context, promotions)
            else if (cardType == PromotionCardType.small)
              _buildSmallCardGrid(context, promotions)
            else
              _buildFullCardList(context, promotions),
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
    return SizedBox(
      height: 201,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          // print('Building mall promotion card: ${promotion.title}');
          return GestureDetector(
            onTap: () {
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
                  if (promotion.previewImage?.url != null &&
                      promotion.previewImage!.url.isNotEmpty)
                    _buildImageWithGradient(promotion.previewImage!.url)
                  else
                    Container(
                      height: 124,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
      itemCount: promotions.length,
      itemBuilder: (context, index) {
        final promotion = promotions[index];
        return GestureDetector(
          onTap: () {
            context.pushNamed(
              'promotion_details',
              pathParameters: {'id': promotion.id.toString()},
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                if (promotion.previewImage?.url != null &&
                    promotion.previewImage!.url.isNotEmpty)
                  _buildImageWithGradient(
                    promotion.previewImage!.url,
                    height: 200,
                    borderRadius: 8,
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 48),
                    ),
                  ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = AppLength.xs * 2;
    const itemSpacing = 12.0;
    final totalSpacing = itemSpacing * (promotions.length - 1);
    final availableWidth = screenWidth - horizontalPadding - totalSpacing;
    final itemWidth = availableWidth / promotions.length;

    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return GestureDetector(
            onTap: () {
              context.pushNamed(
                'promotion_details',
                pathParameters: {'id': promotion.id.toString()},
              );
            },
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.only(
                  right: index != promotions.length - 1 ? itemSpacing : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[300],
                image: promotion.previewImage?.url != null &&
                        promotion.previewImage!.url.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(promotion.previewImage!.url),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: promotion.previewImage?.url == null ||
                      promotion.previewImage!.url.isEmpty
                  ? const Center(
                      child:
                          Icon(Icons.image_not_supported, color: Colors.grey),
                    )
                  : null,
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
