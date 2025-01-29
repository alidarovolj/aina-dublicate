import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/mall_shop_categories_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class StoreCategoriesList extends ConsumerStatefulWidget {
  final String mallId;
  final Function(String?) onCategorySelected;

  const StoreCategoriesList({
    super.key,
    required this.mallId,
    required this.onCategorySelected,
  });

  @override
  ConsumerState<StoreCategoriesList> createState() =>
      _StoreCategoriesListState();
}

class _StoreCategoriesListState extends ConsumerState<StoreCategoriesList> {
  String? selectedCategoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get category from query parameters if available
    final location = GoRouterState.of(context).uri.toString();
    final categoryFromQuery = location.contains('category=')
        ? Uri.parse(location).queryParameters['category']
        : null;

    if (categoryFromQuery != null && categoryFromQuery != selectedCategoryId) {
      setState(() {
        selectedCategoryId = categoryFromQuery;
      });
    }
  }

  @override
  void didUpdateWidget(StoreCategoriesList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if mallId changed
    if (oldWidget.mallId != widget.mallId) {
      print(
          'Mall ID changed from ${oldWidget.mallId} to ${widget.mallId}. Reloading categories...');
      // Invalidate the categories provider to force a refresh
      ref.invalidate(mallShopCategoriesProvider(widget.mallId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync =
        ref.watch(mallShopCategoriesProvider(widget.mallId));

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 80, // Reduced height since we only need 1 line of text
        child: categoriesAsync.when(
          loading: () => _buildSkeletonLoader(),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (categories) {
            final sortedCategories = [...categories]
              ..sort((a, b) => a.order.compareTo(b.order));

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                final isSelected = category.id.toString() == selectedCategoryId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedCategoryId = null;
                        widget.onCategorySelected(null);
                      } else {
                        selectedCategoryId = category.id.toString();
                        widget.onCategorySelected(category.id.toString());

                        // Navigate to category stores page
                        context.pushNamed(
                          'category_stores',
                          pathParameters: {
                            'mallId': widget.mallId,
                            'categoryId': category.id.toString(),
                          },
                          queryParameters: {
                            'title': category.title,
                          },
                        );
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            decoration: BoxDecoration(
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.secondary, width: 1)
                                  : null,
                            ),
                            child: category.image != null
                                ? Image.network(
                                    category.image!.url,
                                    fit: BoxFit.cover,
                                    width: 52,
                                    height: 52,
                                  )
                                : Container(
                                    width: 52,
                                    height: 52,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.category,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 58,
                          child: Text(
                            category.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textDarkGrey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1, // Changed to 1 line
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: 58,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
