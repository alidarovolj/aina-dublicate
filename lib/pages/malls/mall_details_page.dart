import 'package:aina_flutter/shared/types/card_type.dart';
import 'package:aina_flutter/shared/types/news_card_type.dart';
import 'package:aina_flutter/shared/types/slides.dart' as slides;
import 'package:aina_flutter/entities/events_block.dart';
import 'package:aina_flutter/entities/news_block.dart';
import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/widgets/base_slider.dart';
import 'package:aina_flutter/entities/description_block.dart';
import 'package:aina_flutter/entities/mall_info_block.dart';
import 'package:aina_flutter/entities/promotions_block.dart';
import 'package:aina_flutter/entities/categories_grid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aina_flutter/entities/shop_categories_grid.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/providers/requests/mall_categories_provider.dart';
import 'package:aina_flutter/app/providers/requests/mall_shop_categories_provider.dart';

class MallDetailsPage extends ConsumerWidget {
  final int mallId;

  const MallDetailsPage({
    super.key,
    required this.mallId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Если свайп слева направо (положительная скорость) и достаточно быстрый
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          context.pop();
        }
      },
      child: PopScope(
        canPop: true,
        child: buildingsAsync.when(
          loading: () => _buildSkeletonLoader(),
          error: (error, stack) => Builder(
            builder: (context) => GestureDetector(
              onHorizontalDragEnd: (details) {
                // Если свайп слева направо (положительная скорость) и достаточно быстрый
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  context.pop();
                }
              },
              child: Scaffold(
                body: Container(
                  color: AppColors.primary,
                  child: SafeArea(
                    child: Stack(
                      children: [
                        Container(
                          color: AppColors.white,
                          margin: const EdgeInsets.only(top: 64),
                          child: Center(
                            child: Text(
                              'mall.load_error'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        CustomHeader(
                          title: 'mall.title'.tr(),
                          type: HeaderType.pop,
                          onBack: () {
                            context.pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                  context.push('/malls');
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
                              workingHours:
                                  mall.workingHours ?? '10:00 - 22:00',
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
                                context.pushNamed(
                                  'mall_promotions',
                                  pathParameters: {'id': mallId.toString()},
                                );
                              },
                              emptyBuilder: (context) =>
                                  const SizedBox.shrink(),
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
                                CategoriesGrid(
                                  mallId: mallId.toString(),
                                  showDivider: true,
                                  emptyBuilder: (context) => Center(
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
                                        border: Border.all(
                                            color: const Color(0xFFFF5252),
                                            width: 1),
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
                                                  mallCategoriesProvider(
                                                          mallId.toString())
                                                      .notifier);
                                              provider.fetchMallCategories(
                                                  forceRefresh: true);
                                            },
                                            icon: const Icon(Icons.refresh,
                                                color: Colors.white),
                                            label: Text(
                                              'common.refresh'.tr(),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFE53935),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Events Section
                                EventsBlock(
                                  mallId: mallId.toString(),
                                  showTitle: true,
                                  showViewAll: true,
                                  showDivider: true,
                                  cardType: PromotionCardType.medium,
                                  onViewAllTap: () {
                                    context.pushNamed(
                                      'mall_events',
                                      pathParameters: {
                                        'mallId': mallId.toString()
                                      },
                                    );
                                  },
                                  emptyBuilder: (context) =>
                                      const SizedBox.shrink(),
                                ),
                                ShopCategoriesGrid(
                                  mallId: mallId.toString(),
                                  emptyBuilder: (context) => Center(
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
                                        border: Border.all(
                                            color: const Color(0xFFFF5252),
                                            width: 1),
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
                                                  mallShopCategoriesProvider(
                                                          mallId.toString())
                                                      .notifier);
                                              provider.fetchShopCategories(
                                                  forceRefresh: true);
                                            },
                                            icon: const Icon(Icons.refresh,
                                                color: Colors.white),
                                            label: Text(
                                              'common.refresh'.tr(),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFE53935),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomHeader(
                      title: mall.name,
                      type: HeaderType.close,
                      onBack: () {
                        context.go('/home');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Builder(
      builder: (context) => GestureDetector(
        onHorizontalDragEnd: (details) {
          // Если свайп слева направо (положительная скорость) и достаточно быстрый
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            context.pop();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.appBg,
                  margin: const EdgeInsets.only(top: 64),
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      // Description skeleton
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              3,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    height: 16,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Image carousel skeleton
                      SliverToBoxAdapter(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 200,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                      // Mall info skeleton
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Categories skeleton
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 24,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: 8,
                                itemBuilder: (context, index) {
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomHeader(
                  title: 'mall.title'.tr(),
                  type: HeaderType.pop,
                  onBack: () {
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
