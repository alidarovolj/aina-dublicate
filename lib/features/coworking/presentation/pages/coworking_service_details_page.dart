import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:aina_flutter/features/coworking/presentation/widgets/tariff_card.dart';

class CoworkingServiceDetailsPage extends ConsumerWidget {
  final CoworkingService service;
  final List<CoworkingTariff> tariffs;

  const CoworkingServiceDetailsPage({
    super.key,
    required this.service,
    required this.tariffs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      color: AppColors.primary,
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 64),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CarouselWithIndicator(
                      slideList: gallerySlides,
                      showIndicators: true,
                      showGradient: true,
                      height: 200,
                    ),
                    if (service.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                        'Тарифы',
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: tariffs.length,
                      itemBuilder: (context, index) {
                        final tariff = tariffs[index];
                        return TariffCard(
                          tariff: tariff,
                          coworkingId: service.id,
                          onDetailsTap: () {
                            context.pushNamed(
                              'coworking_calendar',
                              pathParameters: {
                                'tariffId': tariff.id.toString()
                              },
                              queryParameters: {'type': 'coworking'},
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            CustomHeader(
              title: service.title,
              type: HeaderType.pop,
            ),
          ],
        ),
      ),
    );
  }
}
