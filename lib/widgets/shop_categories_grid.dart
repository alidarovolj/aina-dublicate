import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/mall_shop_categories_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ShopCategoriesGrid extends ConsumerStatefulWidget {
  final String mallId;
  final Widget Function(BuildContext)? emptyBuilder;

  const ShopCategoriesGrid({
    super.key,
    required this.mallId,
    this.emptyBuilder,
  });

  @override
  ConsumerState<ShopCategoriesGrid> createState() => _ShopCategoriesGridState();
}

class _ShopCategoriesGridState extends ConsumerState<ShopCategoriesGrid> {
  String? _previousMallId;
  AsyncValue<List<dynamic>>? _cachedCategories;

  void _logSubcategoryClick(int categoryId, String categoryName) {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'subcategory_click',
      eventProperties: {
        'Platform': platform,
        'subcategory_id': categoryId,
        'name_subcategory': categoryName,
        'source': 'main',
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _previousMallId = widget.mallId;
  }

  @override
  void didUpdateWidget(ShopCategoriesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if mallId changed
    if (oldWidget.mallId != widget.mallId) {
      _previousMallId = oldWidget.mallId;

      // Use post-frame callback to avoid updating state during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Invalidate the categories provider to force a refresh
          if (widget.mallId.isNotEmpty) {
            ref.invalidate(mallShopCategoriesProvider(widget.mallId));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip loading categories if mallId is empty
    if (widget.mallId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppLength.xs,
              right: AppLength.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'shops.title'.tr(),
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppLength.xs),
            child: Center(
              child: Text('shops.select_mall'.tr()),
            ),
          ),
        ],
      );
    }

    // Use a local variable to capture the current mallId to avoid race conditions
    final currentMallId = widget.mallId;

    // Only watch the provider if we have a valid mallId
    final categoriesAsync = currentMallId.isNotEmpty
        ? ref.watch(mallShopCategoriesProvider(currentMallId))
        : const AsyncValue<List<dynamic>>.data([]);

    // Cache the categories if they're available
    if (categoriesAsync is AsyncData) {
      _cachedCategories = categoriesAsync;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppLength.xs,
            right: AppLength.xs,
            bottom: AppLength.xs,
            top: AppLength.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'shops.title'.tr(),
                style: GoogleFonts.lora(
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (currentMallId.isNotEmpty) {
                    context.pushNamed(
                      'mall_shop_categories',
                      pathParameters: {'id': currentMallId},
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      'shops.view_all'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
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
        categoriesAsync.when(
          loading: () => _buildSkeletonLoader(),
          error: (error, stack) => widget.emptyBuilder != null
              ? widget.emptyBuilder!(context)
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
                            final provider = ref.read(
                                mallShopCategoriesProvider(currentMallId)
                                    .notifier);
                            provider.fetchShopCategories(forceRefresh: true);
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
              return widget.emptyBuilder != null
                  ? widget.emptyBuilder!(context)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'shops.empty'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textDarkGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
            }

            final sortedCategories = [...categories]
              ..sort((a, b) => a.order.compareTo(b.order));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 212,
                ),
                itemCount:
                    sortedCategories.length > 6 ? 6 : sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  return GestureDetector(
                    onTap: () {
                      _logSubcategoryClick(category.id, category.title);
                      context.pushNamed(
                        'mall_stores',
                        pathParameters: {'id': currentMallId},
                        queryParameters: {'category': category.id.toString()},
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: category.image != null
                                ? Image.network(
                                    category.image!.url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 168,
                                  )
                                : Container(
                                    height: 168,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.category),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 4,
                              left: 4,
                              right: 4,
                            ),
                            child: Text(
                              category.title.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDarkGrey,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(AppLength.xs),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 212,
        ),
        itemCount: 4, // Show 4 skeleton items
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Column(
              children: [
                Container(
                  height: 168,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
