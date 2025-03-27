import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/widgets/base_slider.dart';
import 'package:aina_flutter/shared/types/slides.dart' as slides;
import 'package:aina_flutter/pages/coworking/widgets/tariff_card.dart';
import 'package:shimmer/shimmer.dart';

class CoworkingServiceDetailsPage extends ConsumerWidget {
  final CoworkingService service;
  final List<CoworkingTariff> tariffs;
  final int coworkingId;

  const CoworkingServiceDetailsPage({
    super.key,
    required this.service,
    required this.tariffs,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    final gallerySlides = [
      if (service.image != null)
        ...service.gallery.map(
          (image) => slides.Slide(
            id: image.id,
            name: service.title,
            previewImage: slides.PreviewImage(
              id: image.id,
              uuid: image.uuid,
              url: image.url,
              urlOriginal: image.urlOriginal,
              orderColumn: image.orderColumn,
              collectionName: image.collectionName,
            ),
            order: image.orderColumn,
          ),
        ),
    ];

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CarouselWithIndicator(
                      slideList: gallerySlides,
                      showIndicators: true,
                      showGradient: true,
                      height: 200,
                    ),
                    if (service.description?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Html(
                          data: service.description,
                          style: {
                            "body": Style(
                              color: AppColors.primary,
                              fontSize: FontSize(16),
                            ),
                          },
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: AppLength.none, horizontal: AppLength.xs),
                      child: Divider(
                        color: Colors.black12,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'coworking.tariffs.title'.tr(),
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            tariffs.firstOrNull?.type == 'COWORKING' ? 2 : 1,
                        crossAxisSpacing: 15.0,
                        mainAxisSpacing: 15.0,
                        childAspectRatio:
                            tariffs.firstOrNull?.type == 'COWORKING'
                                ? 0.68
                                : 1.8,
                      ),
                      itemCount: tariffs.length,
                      itemBuilder: (context, index) {
                        final tariff = tariffs[index];
                        return TariffCard(
                          tariff: tariff,
                          coworkingId: coworkingId,
                          onDetailsTap: () {
                            context.pushNamed(
                              'coworking_calendar',
                              pathParameters: {
                                'id': coworkingId.toString(),
                                'tariffId': tariff.id.toString()
                              },
                              queryParameters: {
                                'type': tariff.type.toLowerCase()
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              CustomHeader(
                title: service.title,
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildSkeletonLoader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image carousel skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 200,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description skeleton
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
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
                    const SizedBox(height: 16),
                    // Tariffs grid skeleton
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 24,
                              width: 120,
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
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: 4,
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
                  ],
                ),
              ),
              const CustomHeader(title: ''),
            ],
          ),
        ),
      ),
    );
  }
}
