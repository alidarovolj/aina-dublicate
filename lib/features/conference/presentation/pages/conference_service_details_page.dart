import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:aina_flutter/features/conference/domain/models/conference_service.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';

class ConferenceServiceDetailsPage extends ConsumerWidget {
  final ConferenceService service;
  final List<ConferenceTariff> tariffs;

  const ConferenceServiceDetailsPage({
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
                        vertical: AppLength.none,
                        horizontal: AppLength.xs,
                      ),
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
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tariffs.length,
                      itemBuilder: (context, index) {
                        final tariff = tariffs[index];
                        return _buildTariffCard(context, tariff, ref);
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

  Widget _buildTariffCard(
      BuildContext context, ConferenceTariff tariff, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final authState = ref.read(authProvider);
        final isAuthorized = authState.isAuthenticated;

        if (!isAuthorized) {
          BaseModal.show(
            context,
            message: 'Для заказа услуги пройдите регистрацию в приложении',
            buttons: [
              ModalButton(
                label: 'Зарегистрироваться',
                onPressed: () {
                  context.pop();
                  context.pushNamed('login');
                },
              ),
            ],
          );
          return;
        }

        final userData = authState.userData;
        if (userData == null || userData['biometric_valid'] != true) {
          BaseModal.show(
            context,
            message:
                'Для заказа услуги необходимо пройти биометрическую верификацию',
            buttons: [
              ModalButton(
                label: 'Пройти верификацию',
                onPressed: () {
                  context.pop();
                  context.pushNamed('biometric_verification');
                },
              ),
            ],
          );
          return;
        }

        final uri = GoRouterState.of(context).uri;
        final pathSegments = uri.pathSegments;
        final coworkingId =
            pathSegments.length >= 2 && pathSegments[0] == 'coworking'
                ? pathSegments[1]
                : null;

        if (coworkingId == null) {
          print('Error: Could not find coworking ID in route');
          return;
        }

        context.pushNamed(
          'coworking_calendar',
          pathParameters: {'id': coworkingId, 'tariffId': tariff.id.toString()},
          queryParameters: {'type': 'conference'},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            if (tariff.image?.url != null && tariff.image!.url.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(tariff.image!.url),
                    fit: BoxFit.cover,
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 48),
                ),
              ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'до ${tariff.capacity} человек',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      tariff.title.toUpperCase(),
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${tariff.price} ₸/час',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
