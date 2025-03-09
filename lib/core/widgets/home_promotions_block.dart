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

  List<dynamic> _sortPromotions(List<dynamic> promotions) {
    if (!sortByQr) return promotions;

    return List<dynamic>.from(promotions)
      ..sort((a, b) {
        if (a.isQr == b.isQr) return 0;
        return a.isQr ? -1 : 1;
      });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = mallId != null
        ? ref.watch(mallPromotionsProvider(mallId!))
        : ref.watch(promotionsProvider);

    // Добавляем логирование для отладки
    print(
        '🔍 HomePromotionsBlock: состояние промоакций: ${promotionsAsync.toString()}');
    if (promotionsAsync.hasValue) {
      print(
          '✅ HomePromotionsBlock: количество акций: ${promotionsAsync.value?.length ?? 0}');
    }
    if (promotionsAsync.hasError) {
      print('❌ HomePromotionsBlock: ошибка: ${promotionsAsync.error}');
    }

    // Всегда показываем скелетон при загрузке
    if (promotionsAsync.isLoading) {
      return _buildSkeletonLoader(cardType);
    }

    // В случае ошибки показываем ErrorRefreshWidget
    if (promotionsAsync.hasError) {
      print('❌ Ошибка при загрузке промоакций: ${promotionsAsync.error}');

      // Определяем высоту в зависимости от типа карточки
      double height = cardType == PromotionCardType.medium
          ? 201
          : cardType == PromotionCardType.small
              ? 94
              : 200;

      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(
          horizontal: AppLength.xs,
          vertical: AppLength.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: ErrorRefreshWidget(
          onRefresh: () {
            print('🔄 Обновление промоакций...');
            // Используем Future.microtask для асинхронного обновления
            Future.microtask(() {
              try {
                if (mallId != null) {
                  ref.refresh(mallPromotionsProvider(mallId!));
                } else {
                  ref.refresh(promotionsProvider);
                }
              } catch (e) {
                print('❌ Ошибка при обновлении промоакций: $e');
              }
            });
          },
          errorMessage: 'stories.error.loading'.tr(),
          refreshText: 'common.refresh'.tr(),
          icon: Icons.warning_amber_rounded,
          isCompact: cardType == PromotionCardType.small,
          isServerError: true,
          backgroundColor: Colors.transparent,
          textColor: Colors.red.shade900,
          errorColor: Colors.red,
        ),
      );
    }

    // Получаем данные
    final promotions = promotionsAsync.value ?? [];
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

          // Используем Material виджет для лучшего отклика на нажатие
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                print('🔍 Нажатие на акцию с ID: ${promotion.id}');
                // Используем Future.delayed для гарантированного выполнения навигации
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
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLength.xs,
                      vertical: AppLength.four,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Moskva',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
    // Защита от пустого списка
    if (promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    final limitedPromotions = maxElements != null
        ? promotions.take(maxElements!).toList()
        : promotions;

    // Еще одна проверка после ограничения
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
          // Защита от выхода за границы массива
          if (index >= limitedPromotions.length) {
            return const SizedBox.shrink();
          }

          final promotion = limitedPromotions[index];

          // Проверка на наличие URL изображения
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

          // Используем Material виджет для лучшего отклика на нажатие
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                print('🔍 Нажатие на акцию с ID: ${promotion.id}');
                // Используем Future.delayed для гарантированного выполнения навигации
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
}
