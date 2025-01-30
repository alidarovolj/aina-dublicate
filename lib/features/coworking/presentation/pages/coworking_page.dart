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
import 'package:aina_flutter/core/widgets/service_card.dart';
import 'package:aina_flutter/core/types/news_card_type.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class CoworkingPage extends ConsumerWidget {
  final int coworkingId;

  const CoworkingPage({
    super.key,
    required this.coworkingId,
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
        final coworking = (buildings['coworking'] ?? [])
            .firstWhere((building) => building.id == coworkingId);

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
                      // Services Section
                      SliverToBoxAdapter(
                        child: ServiceCard(
                          coworkingId: coworkingId.toString(),
                        ),
                      ),
                      // Promotions Section
                      SliverToBoxAdapter(
                        child: PromotionsBlock(
                          mallId: coworkingId.toString(),
                          showTitle: true,
                          showViewAll: true,
                          showDivider: true,
                          cardType: PromotionCardType.medium,
                          onViewAllTap: () {
                            context.pushNamed(
                              'coworking_promotions',
                              pathParameters: {'id': coworkingId.toString()},
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
                          showGradient: false,
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
                    ],
                  ),
                ),
                CustomHeader(
                  title: coworking.name,
                  type: HeaderType.close,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
