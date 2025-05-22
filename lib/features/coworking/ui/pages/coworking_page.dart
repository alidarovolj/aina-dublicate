import 'package:aina_flutter/app/providers/requests/auth/profile.dart';
import 'package:aina_flutter/app/providers/requests/auth/user.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:aina_flutter/shared/types/slides.dart' as slides;
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/shared/ui/widgets/base_slider.dart';
import 'package:aina_flutter/shared/ui/blocks/description_block.dart';
import 'package:aina_flutter/shared/ui/blocks/mall_info_block.dart';
import 'package:aina_flutter/shared/ui/blocks/news_block.dart';
import 'package:aina_flutter/shared/ui/blocks/promotions_block.dart';
import 'package:aina_flutter/shared/ui/blocks/events_block.dart';
import 'package:aina_flutter/shared/ui/widgets/service_card.dart';
import 'package:aina_flutter/shared/types/news_card_type.dart';
import 'package:aina_flutter/shared/types/card_type.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/app/providers/requests/news_provider.dart';
import 'package:aina_flutter/shared/types/news_params.dart';
import 'package:aina_flutter/features/coworking/ui/widgets/organizations_section.dart';
import 'package:easy_localization/easy_localization.dart';

class CoworkingPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingPage({
    super.key,
    required this.coworkingId,
  });

  @override
  CoworkingPageState createState() => CoworkingPageState();
}

class CoworkingPageState extends ConsumerState<CoworkingPage> {
  @override
  void initState() {
    super.initState();
    // Метод будет вызван только один раз при создании состояния
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOrder(context);
    });
  }

  void _showModalMessage(BuildContext context, String message,
      String buttonTitle, VoidCallback onPressed) {
    BaseModal.show(
      context,
      title: message,
      message: '',
      buttons: [
        ModalButton(label: buttonTitle, onPressed: onPressed),
      ],
    );
  }

  Future<void> _checkOrder(BuildContext context) async {
    try {
      // Выполняем два запроса параллельно
      final responses = await Future.wait([
        ApiClient().dio.get(
              '/api/promenade/profile',
              options: Options(
                extra: {
                  'forceRefresh': true,
                  'cacheTime': 0,
                },
              ),
            ),
        ApiClient().dio.get(
              '/api/promenade/orders/active',
              options: Options(
                extra: {
                  'forceRefresh': true,
                  'cacheTime': 0,
                },
              ),
            ),
      ]);

      final profileResponse = responses[0];
      final ordersResponse = responses[1];

      if (profileResponse.statusCode != 200 ||
          ordersResponse.statusCode != 200) {
        return;
      }

      if (profileResponse.data['success'] != true ||
          ordersResponse.data['success'] != true) {
        return;
      }

      if (profileResponse.data['data'] == null ||
          ordersResponse.data['data'] == null) {
        return;
      }

      var profile = profileResponse.data['data'];
      var order = ordersResponse.data['data'];

      if (profile['biometric_status'] != 'VALID') {
        _showModalMessage(context, 'alerts.biometric_needed.message'.tr(),
            'alerts.biometric_needed.button_title'.tr(), () {
          context.pushNamed('coworking_biometric',
              pathParameters: {'id': widget.coworkingId.toString()});
        });
        return;
      }

      var currentDate = DateTime.now();
      var orderDate = DateTime.parse(order['access']['end_at']);

      // if (orderDate.difference(currentDate).inDays < 1) {
      //   var formattedEndDate = DateFormat('dd.MM.yyyy hh:mm').format(orderDate);
      //   _showModalMessage(
      //       context,
      //       'alerts.coworking_access_expired_soon.message'
      //           .tr(args: [formattedEndDate]),
      //       'alerts.coworking_access_expired_soon.button_title'.tr(), () {
      //     context.pushNamed('coworking_bookings',
      //         pathParameters: {'id': widget.coworkingId.toString()});
      //   });
      // } else {
      //   var formattedEndDate = DateFormat('dd.MM.yyyy').format(orderDate);
      //   _showModalMessage(
      //       context,
      //       'alerts.coworking_access_granted.message'
      //           .tr(args: [formattedEndDate]),
      //       'alerts.coworking_access_granted.button_title'.tr(),
      //       () {});
      // }
    } catch (e) {
      // Обработка ошибок
      print('Ошибка при выполнении запросов: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              .firstWhere((building) => building.id == widget.coworkingId);

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
                            coworkingId: widget.coworkingId.toString(),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        // Organization Section
                        SliverToBoxAdapter(
                          child: OrganizationsSection(
                            coworkingId: widget.coworkingId,
                            showTitle: true,
                            showViewAll: true,
                            showDivider: true,
                            onViewAllTap: () {
                              context.pushNamed(
                                'category_stores',
                                pathParameters: {
                                  'mallId': widget.coworkingId.toString(),
                                  'categoryId': '0',
                                },
                                queryParameters: {
                                  'title': 'organizations.title'.tr(),
                                },
                              );
                            },
                            emptyBuilder: (context) => const SizedBox.shrink(),
                          ),
                        ),
                        // Promotions Section
                        SliverToBoxAdapter(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final newsAsync = ref.watch(newsProvider(
                                NewsParams(
                                  page: 1,
                                  buildingId: widget.coworkingId.toString(),
                                ),
                              ));

                              final hasNews = newsAsync.whenOrNull(
                                    data: (newsResponse) =>
                                        newsResponse.data.isNotEmpty,
                                  ) ??
                                  false;

                              return PromotionsBlock(
                                mallId: widget.coworkingId.toString(),
                                showTitle: true,
                                showViewAll: true,
                                showDivider: true,
                                cardType: PromotionCardType.medium,
                                onViewAllTap: () {
                                  context.pushNamed(
                                    'coworking_promotions',
                                    pathParameters: {
                                      'id': widget.coworkingId.toString()
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
                          child: Consumer(
                            builder: (context, ref, child) {
                              return EventsBlock(
                                mallId: widget.coworkingId.toString(),
                                showTitle: true,
                                showViewAll: true,
                                showDivider: true,
                                cardType: PromotionCardType.medium,
                                onViewAllTap: () {
                                  context.pushNamed(
                                    'coworking_promotions',
                                    pathParameters: {
                                      'id': widget.coworkingId.toString()
                                    },
                                    extra: {'initialTabIndex': 1},
                                  );
                                },
                                emptyBuilder: (context) =>
                                    const SizedBox.shrink(),
                              );
                            },
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
                            buildingId: widget.coworkingId.toString(),
                            onViewAllTap: () {
                              context.pushNamed(
                                'coworking_news',
                                pathParameters: {
                                  'id': widget.coworkingId.toString()
                                },
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
