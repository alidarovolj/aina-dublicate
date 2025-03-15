import 'package:flutter/material.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/widgets/description_block.dart';
import 'package:aina_flutter/core/widgets/mall_info_block.dart';
import 'package:aina_flutter/core/widgets/news_block.dart';
import 'package:aina_flutter/core/widgets/promotions_block.dart';
import 'package:aina_flutter/core/widgets/events_block.dart';
import 'package:aina_flutter/core/widgets/service_card.dart';
import 'package:aina_flutter/core/types/news_card_type.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/providers/requests/news_provider.dart';
import 'package:aina_flutter/core/types/news_params.dart';

class CoworkingPage extends ConsumerWidget {
  final int coworkingId;

  const CoworkingPage({
    super.key,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          context.go('/home');
        }
      },
      child: buildingsAsync.when(
        loading: () => Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Stack(
              children: [
                _buildSkeletonLoader(),
                CustomHeader(
                  title: '',
                  type: HeaderType.close,
                  onBack: () {
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (buildings) {
          final coworking = (buildings['coworking'] ?? [])
              .firstWhere((building) => building.id == coworkingId);

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
                            text: coworking.description ?? '',
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: CarouselWithIndicator(
                            slideList: (coworking.images)
                                .map((image) => slides.Slide(
                                      id: image.id,
                                      name: coworking.name,
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
                          child: SizedBox(height: 20),
                        ),
                        // Coworking Info
                        SliverToBoxAdapter(
                          child: MallInfoBlock(
                            workingHours:
                                coworking.workingHours ?? '10:00 - 22:00',
                            address: coworking.address ?? '',
                            onCallTap: () async {
                              final phoneNumber = coworking.phone;
                              final uri = Uri.parse('tel:$phoneNumber');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            onMapTap: () async {
                              final lat = coworking.latitude;
                              final lng = coworking.longitude;
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
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 28),
                        ),
                        // Services Section
                        SliverToBoxAdapter(
                          child: ServiceCard(
                            coworkingId: coworkingId.toString(),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        // Promotions Section
                        SliverToBoxAdapter(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final newsAsync = ref.watch(newsProvider(
                                NewsParams(
                                  page: 1,
                                  buildingId: coworkingId.toString(),
                                ),
                              ));

                              final hasNews = newsAsync.whenOrNull(
                                    data: (newsResponse) =>
                                        newsResponse.data.isNotEmpty,
                                  ) ??
                                  false;

                              return PromotionsBlock(
                                mallId: coworkingId.toString(),
                                showTitle: true,
                                showViewAll: true,
                                showDivider: true,
                                cardType: PromotionCardType.medium,
                                onViewAllTap: () {
                                  context.pushNamed(
                                    'coworking_promotions',
                                    pathParameters: {
                                      'id': coworkingId.toString()
                                    },
                                  );
                                },
                                emptyBuilder: (context) =>
                                    const SizedBox.shrink(),
                              );
                            },
                          ),
                        ),
                        // Events Section
                        SliverToBoxAdapter(
                          child: EventsBlock(
                            mallId: coworkingId.toString(),
                            showTitle: true,
                            showViewAll: true,
                            showDivider: true,
                            cardType: PromotionCardType.medium,
                            onViewAllTap: () {
                              context.pushNamed(
                                'coworking_promotions',
                                pathParameters: {'id': coworkingId.toString()},
                                extra: {'initialTabIndex': 1},
                              );
                            },
                            emptyBuilder: (context) => const SizedBox.shrink(),
                          ),
                        ),
                        // News Section
                        SliverToBoxAdapter(
                          child: NewsBlock(
                            showTitle: true,
                            showViewAll: true,
                            showDivider: false,
                            showGradient: true,
                            cardType: NewsCardType.full,
                            buildingId: coworkingId.toString(),
                            onViewAllTap: () {
                              context.pushNamed(
                                'coworking_news',
                                pathParameters: {'id': coworkingId.toString()},
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
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 30),
                        ),
                      ],
                    ),
                  ),
                  CustomHeader(
                    title: coworking.name,
                    type: HeaderType.pop,
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
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      color: AppColors.appBg,
      margin: const EdgeInsets.only(top: 64), // Height of CustomHeader
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Description skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppLength.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
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
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.grey[300]!,
              child: Container(
                height: 200,
                color: Colors.grey[300],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
          // Mall info skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppLength.xs),
              child: Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[100]!,
                          highlightColor: Colors.grey[300]!,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[100]!,
                            highlightColor: Colors.grey[300]!,
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Services skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppLength.xs),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          // Promotions skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppLength.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[100]!,
                          highlightColor: Colors.grey[300]!,
                          child: Container(
                            width: 280,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // News skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppLength.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
