import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/mall_categories_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class CategoriesGrid extends ConsumerWidget {
  final String mallId;
  final bool showDivider;
  final Widget Function(BuildContext)? emptyBuilder;

  const CategoriesGrid({
    super.key,
    required this.mallId,
    this.showDivider = false,
    this.emptyBuilder,
  });

  void _logContentTypeClick(int categoryId, String categoryName) {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'content_type',
      eventProperties: {
        'Platform': platform,
        'category_id': categoryId,
        'name_category': categoryName,
        'source': 'mall',
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(mallCategoriesProvider(mallId));

    // Calculate the width of each grid item
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = AppLength.xs * 2; // Total horizontal padding
    const spacing = 12.0 * 2; // Total spacing between items
    final itemWidth = (screenWidth - padding - spacing) / 3;
    // Set aspect ratio to achieve 107px height
    final aspectRatio = itemWidth / 107;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppLength.xs),
          child: Text(
            'categories.title'.tr(),
            style: GoogleFonts.lora(
              fontSize: 22,
              color: Colors.black,
            ),
          ),
        ),
        categoriesAsync.when(
          loading: () => _buildSkeletonLoader(aspectRatio),
          error: (error, stack) => emptyBuilder != null
              ? emptyBuilder!(context)
              : Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppLength.xs,
                      vertical: AppLength.xs,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDDDD),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color(0xFFFF5252), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE53935),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'stories.error.loading'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            final provider = ref
                                .read(mallCategoriesProvider(mallId).notifier);
                            provider.fetchMallCategories(forceRefresh: true);
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: Text(
                            'common.refresh'.tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          data: (categories) {
            if (categories.isEmpty) {
              return emptyBuilder != null
                  ? emptyBuilder!(context)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'categories.empty'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textDarkGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
            }

            // Sort categories by order
            final sortedCategories = [...categories]
              ..sort((a, b) => a.order.compareTo(b.order));

            return Padding(
              padding: const EdgeInsets.only(
                left: AppLength.xs,
                right: AppLength.xs,
                top: AppLength.xs,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  return GestureDetector(
                    onTap: () {
                      _logContentTypeClick(category.id, category.title);
                      context.pushNamed(
                        'category_stores',
                        pathParameters: {
                          'mallId': mallId,
                          'categoryId': category.id.toString(),
                        },
                        queryParameters: {
                          'title': category.title,
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          // Background image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: category.image != null
                                ? Image.network(
                                    category.image!.url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.category),
                                  ),
                          ),
                          // Title in top-left corner
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        if (showDivider) const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.only(
            left: AppLength.xs,
            right: AppLength.xs,
          ),
          child: const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.lightGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader(double aspectRatio) {
    return Padding(
      padding: const EdgeInsets.all(AppLength.xs),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemCount: 6, // Show 6 skeleton items
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }
}
