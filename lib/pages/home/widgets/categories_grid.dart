import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/mall_categories_provider.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesGrid extends ConsumerWidget {
  final String mallId;

  const CategoriesGrid({
    super.key,
    required this.mallId,
  });

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
            'Категории',
            style: GoogleFonts.lora(fontSize: 22, color: Colors.black),
          ),
        ),
        categoriesAsync.when(
          loading: () => _buildSkeletonLoader(aspectRatio),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (categories) {
            // Sort categories by order
            final sortedCategories = [...categories]
              ..sort((a, b) => a.order.compareTo(b.order));

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
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  return GestureDetector(
                    onTap: () {
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // Background image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}
