import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/mall_shop_categories_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class StoreCategoriesList extends ConsumerStatefulWidget {
  final String mallId;
  final Function(String?) onCategorySelected;
  final bool useRouting;

  const StoreCategoriesList({
    super.key,
    required this.mallId,
    required this.onCategorySelected,
    this.useRouting = true,
  });

  @override
  ConsumerState<StoreCategoriesList> createState() =>
      _StoreCategoriesListState();
}

class _StoreCategoriesListState extends ConsumerState<StoreCategoriesList> {
  String? selectedCategoryId;
  String? _previousMallId;

  @override
  void initState() {
    super.initState();
    _previousMallId = widget.mallId;
  }

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
      _previousMallId = oldWidget.mallId;

      // Use post-frame callback to avoid updating state during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Only invalidate the provider if we have a valid mallId
          if (widget.mallId.isNotEmpty) {
            // Invalidate the categories provider to force a refresh
            ref.invalidate(mallShopCategoriesProvider(widget.mallId));
          }

          // Reset selected category when mall changes
          if (selectedCategoryId != null) {
            setState(() {
              selectedCategoryId = null;
            });
            widget.onCategorySelected(null);
          }
        }
      });
    }
  }

  // Handle category selection without setState during build
  void _handleCategorySelection(
      String categoryId, bool isSelected, String title) {
    // Use post-frame callback to avoid updating state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (isSelected) {
            selectedCategoryId = null;
          } else {
            selectedCategoryId = categoryId;
          }
        });

        widget.onCategorySelected(isSelected ? null : categoryId);

        if (widget.useRouting && !isSelected) {
          context.pushNamed(
            'category_stores',
            pathParameters: {
              'mallId': widget.mallId,
              'categoryId': categoryId,
            },
            queryParameters: {
              'title': title,
            },
          );
        }
      }
    });
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 58,
                  height: 10,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Всегда показываем категории, даже если mallId пустой (для опции "Все ТРЦ")
    // Если mallId пустой, запрос будет отправлен без параметра building_id
    final categoriesAsync =
        ref.watch(mallShopCategoriesProvider(widget.mallId));

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 70, // Уменьшенная высота для компактности
        child: categoriesAsync.when(
          loading: () => _buildSkeletonLoader(),
          error: (error, stack) => Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppLength.xs,
                vertical: 4, // Уменьшенный отступ для компактности
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0), // Уменьшенные отступы для компактности
              decoration: BoxDecoration(
                color: const Color(0xFFFFDDDD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF5252), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE53935),
                    size: 20, // Уменьшенный размер иконки
                  ),
                  const SizedBox(width: 6), // Уменьшенный отступ
                  Flexible(
                    child: Text(
                      'stories.error.loading'.tr(),
                      style: const TextStyle(
                        fontSize: 12, // Уменьшенный размер шрифта
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6), // Уменьшенный отступ
                  ElevatedButton(
                    onPressed: () {
                      final provider = ref.read(
                          mallShopCategoriesProvider(widget.mallId).notifier);
                      provider.fetchShopCategories(forceRefresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2), // Уменьшенные отступы
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      minimumSize:
                          const Size(50, 24), // Уменьшенный размер кнопки
                    ),
                    child: Text(
                      'common.refresh'.tr(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10), // Уменьшенный размер шрифта
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (categories) {
            final sortedCategories = [...categories]
              ..sort((a, b) => a.order.compareTo(b.order));

            if (sortedCategories.isEmpty) {
              return Center(
                child: Text('No categories available'),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                final isSelected = category.id.toString() == selectedCategoryId;

                return GestureDetector(
                  onTap: () => _handleCategorySelection(
                      category.id.toString(), isSelected, category.title),
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

  // Add dispose method to handle cleanup
  @override
  void dispose() {
    // We don't need to do any cleanup for the provider here
    // The provider will be automatically disposed when no longer in use
    super.dispose();
  }
}
