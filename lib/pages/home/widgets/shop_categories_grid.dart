import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/mall_shop_categories_provider.dart';
import 'package:shimmer/shimmer.dart';

class ShopCategoriesGrid extends ConsumerStatefulWidget {
  final String mallId;

  const ShopCategoriesGrid({
    super.key,
    required this.mallId,
  });

  @override
  ConsumerState<ShopCategoriesGrid> createState() => _ShopCategoriesGridState();
}

class _ShopCategoriesGridState extends ConsumerState<ShopCategoriesGrid> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(ShopCategoriesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if mallId changed
    if (oldWidget.mallId != widget.mallId) {
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
            padding: const EdgeInsets.all(AppLength.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Магазины',
                  style: GoogleFonts.lora(fontSize: 22, color: Colors.black),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppLength.xs),
            child: Center(
              child: Text('Выберите ТРЦ для просмотра магазинов'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppLength.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Магазины',
                style: GoogleFonts.lora(fontSize: 22, color: Colors.black),
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
                child: Row(
                  children: [
                    Text(
                      'Все',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        categoriesAsync.when(
          loading: () => _buildSkeletonLoader(),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (categories) {
            final sortedCategories = [...categories]
              ..sort((a, b) => a.order.compareTo(b.order));

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
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  return GestureDetector(
                    onTap: () {
                      context.pushNamed(
                        'mall_stores',
                        pathParameters: {'id': currentMallId},
                        queryParameters: {'category': category.id.toString()},
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
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
