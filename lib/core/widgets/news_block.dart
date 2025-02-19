import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/news_provider.dart';
import 'package:aina_flutter/core/types/news_card_type.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/types/news_params.dart';
import 'package:easy_localization/easy_localization.dart';

class NewsBlock extends ConsumerWidget {
  final VoidCallback? onViewAllTap;
  final bool showTitle;
  final bool showViewAll;
  final bool showDivider;
  final bool showGradient;
  final Widget Function(BuildContext)? emptyBuilder;
  final int? maxElements;
  final String? buildingId;
  final NewsCardType cardType;

  const NewsBlock({
    super.key,
    this.onViewAllTap,
    this.showTitle = true,
    this.showViewAll = true,
    this.showDivider = true,
    this.showGradient = false,
    this.emptyBuilder,
    this.maxElements,
    this.buildingId,
    this.cardType = NewsCardType.medium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider(
      NewsParams(
        page: 1,
        buildingId: buildingId,
      ),
    ));

    return newsAsync.when(
      loading: () => _buildSkeletonLoader(cardType),
      error: (error, stack) => const SizedBox.shrink(),
      data: (newsResponse) {
        if (newsResponse.data.isEmpty) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }

        final limitedNews = maxElements != null
            ? newsResponse.data.take(maxElements!).toList()
            : newsResponse.data;

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
                        'news.title'.tr(),
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    if (showViewAll && onViewAllTap != null)
                      TextButton(
                        onPressed: onViewAllTap,
                        child: Row(
                          children: [
                            Text(
                              'news.view_all'.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            SvgPicture.asset(
                              'lib/core/assets/icons/chevron-right.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
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
            if (cardType == NewsCardType.medium)
              _buildMediumCardList(context, limitedNews)
            else if (cardType == NewsCardType.small)
              _buildSmallCardGrid(context, limitedNews)
            else
              _buildFullCardList(context, limitedNews),
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

  Widget _buildMediumCardList(BuildContext context, List<dynamic> news) {
    return SizedBox(
      height: 201,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: news.length,
        itemBuilder: (context, index) {
          final newsItem = news[index];
          return GestureDetector(
            onTap: () {
              context.pushNamed(
                'news_details',
                pathParameters: {'id': newsItem.id.toString()},
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
                      _buildImageWithGradient(newsItem.previewImage.url),
                      if (newsItem.building != null)
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
                            child: Text(
                              newsItem.building!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    newsItem.title,
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    newsItem.formattedDate,
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

  Widget _buildFullCardList(BuildContext context, List<dynamic> news) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
      itemCount: news.length,
      itemBuilder: (context, index) {
        final newsItem = news[index];
        return GestureDetector(
          onTap: () {
            context.pushNamed(
              'news_details',
              pathParameters: {'id': newsItem.id.toString()},
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                _buildImageWithGradient(
                  newsItem.previewImage.url,
                  height: 200,
                  borderRadius: 8,
                ),
                if (newsItem.building != null)
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
                      child: Text(
                        newsItem.building!.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                        newsItem.title,
                        style: GoogleFonts.lora(
                          fontSize: 17,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        newsItem.formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
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

  Widget _buildSmallCardGrid(BuildContext context, List<dynamic> news) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = AppLength.xs * 2;
    const itemSpacing = 12.0;
    final totalSpacing = itemSpacing * (news.length - 1);
    final availableWidth = screenWidth - horizontalPadding - totalSpacing;
    final itemWidth = availableWidth / news.length;

    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: news.length,
        itemBuilder: (context, index) {
          final newsItem = news[index];
          return GestureDetector(
            onTap: () {
              context.pushNamed(
                'news_details',
                pathParameters: {'id': newsItem.id.toString()},
              );
            },
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.only(
                  right: index != news.length - 1 ? itemSpacing : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(newsItem.previewImage.url),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
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

  Widget _buildSkeletonLoader(NewsCardType type) {
    if (type == NewsCardType.medium) {
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
    } else if (type == NewsCardType.small) {
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
