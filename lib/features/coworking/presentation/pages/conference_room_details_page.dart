import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:aina_flutter/features/coworking/providers/coworking_service_provider.dart'
    as service_provider;
import 'package:aina_flutter/features/coworking/presentation/widgets/conference_tariff_card.dart'
    as conference;
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/tariff_card.dart';

class ConferenceRoomDetailsPage extends ConsumerWidget with AuthCheckMixin {
  final CoworkingTariff tariff;
  final int coworkingId;

  const ConferenceRoomDetailsPage({
    super.key,
    required this.tariff,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarTariffsAsync = ref.watch(
      service_provider.coworkingTariffsProvider(tariff.categoryId),
    );

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 64),
                      child: Column(
                        children: [
                          if (tariff.image != null)
                            Image.network(
                              tariff.image!.url,
                              width: double.infinity,
                              height: 240,
                              fit: BoxFit.cover,
                            ),
                          Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppLength.xs, vertical: 0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom:
                                          BorderSide(color: Colors.grey[200]!),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'conference_room.capacity'.tr(),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: AppColors.darkGrey,
                                              ),
                                            ),
                                            Text(
                                              'conference_room.capacity_value'
                                                  .tr(args: [
                                                tariff.capacity.toString()
                                              ]),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: AppColors.almostBlack,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 64,
                                        width: 1,
                                        color: Colors.grey[200],
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'conference_room.price'.tr(),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: AppColors.darkGrey,
                                              ),
                                            ),
                                            Text(
                                              'conference_room.price_value'.tr(
                                                  args: [
                                                    tariff.price.toString()
                                                  ]),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: AppColors.almostBlack,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Html(
                                  data: tariff.description,
                                  style: {
                                    "body": Style(
                                      fontSize: FontSize(16),
                                      lineHeight: const LineHeight(1.5),
                                      color: AppColors.primary,
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                    ),
                                    "p": Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                    ),
                                  },
                                ),
                                const SizedBox(height: 32),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppLength.xs),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomButton(
                                          onPressed: () async {
                                            if (await checkAuthAndBiometric(
                                                context, ref, coworkingId)) {
                                              context.pushNamed(
                                                'coworking_calendar',
                                                pathParameters: {
                                                  'id': coworkingId.toString(),
                                                  'tariffId':
                                                      tariff.id.toString(),
                                                },
                                                queryParameters: {
                                                  'type': 'conference',
                                                },
                                              );
                                            }
                                          },
                                          isFullWidth: true,
                                          label: 'conference_room.book'.tr(),
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey[200]!),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'conference_room.similar_services'
                                              .tr(),
                                          style: GoogleFonts.lora(
                                            fontSize: 22,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        similarTariffsAsync.when(
                                          loading: () => Column(
                                            children: List.generate(
                                              2,
                                              (index) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 24),
                                                child: Shimmer.fromColors(
                                                  baseColor: Colors.grey[300]!,
                                                  highlightColor:
                                                      Colors.grey[100]!,
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: 240,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          error: (error, stack) => Center(
                                            child: Text(
                                              'Error: $error',
                                              style: const TextStyle(
                                                  color: AppColors.primary),
                                            ),
                                          ),
                                          data: (tariffs) {
                                            final similarTariffs = tariffs
                                                .where((t) => t.id != tariff.id)
                                                .take(2)
                                                .toList();
                                            return ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: similarTariffs.length,
                                              itemBuilder: (context, index) {
                                                final similarTariff =
                                                    similarTariffs[index];
                                                return conference
                                                    .ConferenceTariffCard(
                                                  tariff: similarTariff,
                                                  coworkingId: coworkingId,
                                                  serviceId: tariff.categoryId,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CustomHeader(
                title: tariff.title,
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
                    // Image skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 200,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Details skeleton
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          4,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 24,
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
                    // Similar services skeleton
                    Padding(
                      padding: const EdgeInsets.all(16),
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
                          Row(
                            children: List.generate(
                              2,
                              (index) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 8,
                                    right: index == 1 ? 0 : 8,
                                  ),
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
                            ),
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
