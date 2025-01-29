import 'package:aina_flutter/core/types/card_type.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/widgets/description_block.dart';
import 'package:aina_flutter/core/widgets/mall_info_block.dart';
import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/widgets/categories_grid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aina_flutter/core/widgets/shop_categories_grid.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/mall_promotions_block.dart';

class MallDetailsPage extends ConsumerWidget {
  final int mallId;

  const MallDetailsPage({
    super.key,
    required this.mallId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return buildingsAsync.when(
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: AppLength.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (buildings) {
        final mall = (buildings['mall'] ?? [])
            .firstWhere((building) => building.id == mallId);

        return Scaffold(
          body: Container(
            color: AppColors.primary,
            child: SafeArea(
              child: Stack(
                children: [
                  Container(
                    color: AppColors.appBg,
                    margin: const EdgeInsets.only(
                        top: 64), // Height of CustomHeader
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: DescriptionBlock(
                            text: mall.description ?? '',
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: CarouselWithIndicator(
                            slideList: (mall.images)
                                .map((image) => slides.Slide(
                                      id: image.id,
                                      name: mall.name,
                                      previewImage: slides.PreviewImage(
                                        id: image.id,
                                        uuid: image.uuid,
                                        url: image.url,
                                        urlOriginal: image.urlOriginal,
                                        orderColumn: image.orderColumn,
                                        collectionName: image.collectionName,
                                      ),
                                      order: image.orderColumn,
                                    ))
                                .toList(),
                            showIndicators: true,
                            showGradient: true,
                            height: 200,
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 20,
                          ),
                        ),
                        // Mall Info
                        SliverToBoxAdapter(
                          child: MallInfoBlock(
                            workingHours: mall.workingHours ?? '10:00 - 22:00',
                            address: mall.address ?? '',
                            onCallTap: () async {
                              final phoneNumber = mall.phone;
                              final uri = Uri.parse('tel:$phoneNumber');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            onMapTap: () async {
                              final lat = mall.latitude;
                              final lng = mall.longitude;
                              final uri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                          ),
                        ),

                        // Promotions Section
                        SliverToBoxAdapter(
                          child: MallPromotionsBlock(
                            mallId: mallId.toString(),
                            showTitle: true,
                            showViewAll: true,
                            showDivider: true,
                            cardType: PromotionCardType.medium,
                            onViewAllTap: () {
                              context.goNamed(
                                'mall_promotions',
                                pathParameters: {'id': mallId.toString()},
                              );
                            },
                            emptyBuilder: (context) => const SizedBox.shrink(),
                          ),
                        ),

                        // Categories Section
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              CategoriesGrid(mallId: mallId.toString()),
                              const SizedBox(height: 16),
                              ShopCategoriesGrid(mallId: mallId.toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomHeader(
                    title: mall.name,
                    type: HeaderType.close,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildShopCategory(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
