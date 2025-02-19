import 'package:aina_flutter/core/types/card_type.dart';
import 'package:aina_flutter/core/types/news_card_type.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:aina_flutter/core/widgets/news_block.dart';
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
        final malls = buildings['mall'] ?? [];
        final mall = malls.firstWhere(
          (building) => building.id == mallId,
          orElse: () => malls.first,
        );

        // Если ID не совпадает, выполняем навигацию после построения виджета
        if (mall.id != mallId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/malls');
            }
          });
        }

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.appBg,
                  margin:
                      const EdgeInsets.only(top: 64), // Height of CustomHeader
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
                            // 2GIS KZ route URL
                            final uri = Uri.parse(
                                'https://2gis.kz/almaty/routeSearch/to/$lng,$lat');

                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),

                      // Promotions Section
                      SliverToBoxAdapter(
                        child: PromotionsBlock(
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
                      // News Section
                      SliverToBoxAdapter(
                        child: NewsBlock(
                          showTitle: true,
                          showViewAll: false,
                          showDivider: true,
                          showGradient: false,
                          cardType: NewsCardType.medium,
                          buildingId: mallId.toString(),
                          onViewAllTap: () {
                            context.pushNamed(
                              'coworking_news',
                              pathParameters: {'id': mallId.toString()},
                            );
                          },
                          emptyBuilder: (context) => const Center(
                            child: Text(
                              'В данный момент нет новостей',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                          ),
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
