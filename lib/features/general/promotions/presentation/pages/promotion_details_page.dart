import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/promotion_details_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:aina_flutter/features/general/scanner/widgets/auth_warning_modal.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';
import 'package:aina_flutter/core/types/button_config.dart';
import 'package:intl/intl.dart';
import 'package:aina_flutter/core/types/promotion.dart';

class PromotionDetailsPage extends ConsumerWidget {
  final int id;

  const PromotionDetailsPage({
    super.key,
    required this.id,
  });

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formattedDateRange(Promotion promotion) {
    if (promotion.startAt == null && promotion.endAt == null) {
      return 'promotions.unlimited'.tr();
    }
    if (promotion.startAt != null && promotion.endAt != null) {
      return '${'promotions.from_date'.tr()} ${DateFormat('dd.MM.yyyy').format(promotion.startAt!)} ${'promotions.until_date'.tr()} ${DateFormat('dd.MM.yyyy').format(promotion.endAt!)}';
    }
    if (promotion.startAt != null) {
      return '${'promotions.from_date'.tr()} ${DateFormat('dd.MM.yyyy').format(promotion.startAt!)}';
    }
    if (promotion.endAt != null) {
      return '${'promotions.until_date'.tr()} ${DateFormat('dd.MM.yyyy').format(promotion.endAt!)}';
    }
    return '';
  }

  Widget _buildSkeleton() {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: 64),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[300]!,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppLength.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      height: 28,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLength.sm),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[300]!,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppLength.xs),
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppLength.sm),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[300]!,
                    child: Column(
                      children: List.generate(
                          3,
                          (index) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )),
                    ),
                  ),
                  const SizedBox(height: AppLength.sm),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLength.sm),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[300]!,
                    child: Column(
                      children: List.generate(
                          5,
                          (index) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionAsync = ref.watch(promotionDetailsProvider(id.toString()));

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              promotionAsync.when(
                loading: () => _buildSkeleton(),
                error: (error, stack) => Center(
                  child: Text('promotions.error'.tr(args: [error.toString()])),
                ),
                data: (promotion) => Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            promotion.previewImage.url,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppLength.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promotion.title,
                                style: GoogleFonts.lora(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(height: AppLength.sm),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'lib/core/assets/icons/calendar.svg',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: AppLength.xs),
                                  Text(
                                    _formattedDateRange(promotion),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                ],
                              ),
                              if (promotion.file != null) ...[
                                const SizedBox(height: AppLength.sm),
                                TextButton(
                                  onPressed: () {
                                    if (promotion.file?.url != null) {
                                      _launchUrl(promotion.file!.url!);
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'promotions.view_terms'.tr(),
                                        style: TextStyle(
                                          color: AppColors.blueGrey,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppLength.sm),
                              if (promotion.type == 'QR' && promotion.isQr)
                                CustomButton(
                                  label: 'promotions.scan_qr'.tr(),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () {
                                    AmplitudeService().logEvent(
                                      'scan_pageinfo_click',
                                      eventProperties: {
                                        'Platform': _getPlatform(),
                                      },
                                    );

                                    final authState = ref.read(authProvider);
                                    final mallId =
                                        promotion.building?.id.toString();

                                    if (mallId == null) {
                                      BaseSnackBar.show(
                                        context,
                                        message:
                                            'promotions.error.no_mall'.tr(),
                                        type: SnackBarType.error,
                                      );
                                      return;
                                    }

                                    if (!authState.isAuthenticated) {
                                      AuthWarningModal.show(
                                        context,
                                        promotionId: id.toString(),
                                        mallId: mallId,
                                      );
                                    } else if (!authState.hasCompletedProfile) {
                                      AuthWarningModal.show(
                                        context,
                                        isProfileIncomplete: true,
                                        promotionId: id.toString(),
                                        mallId: mallId,
                                      );
                                    } else {
                                      context.pushNamed(
                                        'promotion_qr',
                                        pathParameters: {
                                          'promotionId':
                                              promotion.id.toString(),
                                        },
                                        queryParameters: {
                                          'mallId': mallId,
                                        },
                                      );
                                    }
                                  },
                                )
                              else if (promotion.type == 'SERVICE_PURCHASE')
                                CustomButton(
                                  label: 'coworking.tariffs.title'.tr(),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () {
                                    print(
                                        '=== DEBUG: Service Purchase Button Pressed ===');
                                    print(
                                        'Building ID: ${promotion.building?.id}');
                                    print(
                                        'Building Type: ${promotion.building?.type}');
                                    print('Promotion Type: ${promotion.type}');

                                    if (promotion.building?.id != null) {
                                      print(
                                          'Attempting navigation to coworking_details');
                                      print(
                                          'Path Parameters: id=${promotion.building!.id}');
                                      print('Extra Parameters: initialTab=1');

                                      context.pushReplacementNamed(
                                        'coworking_services',
                                        pathParameters: {
                                          'id':
                                              promotion.building!.id.toString(),
                                        },
                                      );
                                    } else {
                                      print('ERROR: Building ID is null');
                                    }
                                  },
                                )
                              else if (promotion.type == 'RAFFLE' &&
                                  promotion.isQr)
                                CustomButton(
                                  label: 'promotions.scan_qr'.tr(),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () {
                                    AmplitudeService().logEvent(
                                      'scan_pageinfo_click',
                                      eventProperties: {
                                        'Platform': _getPlatform(),
                                      },
                                    );

                                    final authState = ref.read(authProvider);
                                    final mallId =
                                        promotion.building?.id.toString();

                                    if (mallId == null) {
                                      BaseSnackBar.show(
                                        context,
                                        message:
                                            'promotions.error.no_mall'.tr(),
                                        type: SnackBarType.error,
                                      );
                                      return;
                                    }

                                    if (!authState.isAuthenticated) {
                                      AuthWarningModal.show(
                                        context,
                                        promotionId: id.toString(),
                                        mallId: mallId,
                                      );
                                    } else if (!authState.hasCompletedProfile) {
                                      AuthWarningModal.show(
                                        context,
                                        isProfileIncomplete: true,
                                        promotionId: id.toString(),
                                        mallId: mallId,
                                      );
                                    } else {
                                      context.pushNamed(
                                        'promotion_qr',
                                        pathParameters: {
                                          'promotionId':
                                              promotion.id.toString(),
                                        },
                                        queryParameters: {
                                          'mallId': mallId,
                                        },
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(height: AppLength.sm),
                              Html(
                                data: promotion.subtitle,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(15),
                                    lineHeight: const LineHeight(1.5),
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    color: AppColors.textDarkGrey,
                                  ),
                                  "a": Style(
                                    color: Colors.blue,
                                    textDecoration: TextDecoration.underline,
                                  ),
                                },
                                onLinkTap: (url, context, attributes) {
                                  if (url != null) _launchUrl(url);
                                },
                              ),
                              const SizedBox(height: AppLength.sm),
                              Html(
                                data: promotion.body,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(15),
                                    lineHeight: const LineHeight(1.5),
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    color: AppColors.textDarkGrey,
                                  ),
                                  "a": Style(
                                    color: Colors.blue,
                                    textDecoration: TextDecoration.underline,
                                  ),
                                },
                                onLinkTap: (url, context, attributes) {
                                  if (url != null) _launchUrl(url);
                                },
                              ),
                              CustomButton(
                                button: promotion.button != null
                                    ? ButtonConfig(
                                        label: promotion.button!.label,
                                        isInternal:
                                            promotion.button!.isInternal,
                                        internal:
                                            promotion.button!.internal != null
                                                ? ButtonInternal(
                                                    model: promotion.button!
                                                        .internal!.model,
                                                    id: promotion
                                                        .button!.internal!.id,
                                                    buildingType: promotion
                                                        .button!
                                                        .internal!
                                                        .buildingType,
                                                    isAuthRequired: promotion
                                                        .button!
                                                        .internal!
                                                        .isAuthRequired,
                                                  )
                                                : null,
                                      )
                                    : null,
                                isFullWidth: true,
                                backgroundColor: AppColors.primary,
                              ),
                              if (promotion.images.isNotEmpty) ...[
                                const SizedBox(height: AppLength.sm),
                                CarouselWithIndicator(
                                  slideList: promotion.images
                                      .map((image) => slides.Slide(
                                            id: image.id,
                                            name: promotion.title,
                                            previewImage: slides.PreviewImage(
                                              id: image.id,
                                              uuid: image.uuid,
                                              url: image.url,
                                              urlOriginal: image.urlOriginal,
                                              orderColumn: image.orderColumn,
                                              collectionName:
                                                  image.collectionName,
                                            ),
                                            order: image.orderColumn,
                                          ))
                                      .toList(),
                                  showIndicators: true,
                                  showGradient: false,
                                  height: 200,
                                ),
                              ],
                              if (promotion.bottomBody != null &&
                                  promotion.bottomBody!.isNotEmpty) ...[
                                const SizedBox(height: AppLength.sm),
                                Html(
                                  data: promotion.bottomBody!,
                                  style: {
                                    "body": Style(
                                      fontSize: FontSize(13),
                                      color: AppColors.textDarkGrey,
                                      lineHeight: const LineHeight(1.5),
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                    ),
                                    "a": Style(
                                      color: Colors.blue,
                                      textDecoration: TextDecoration.underline,
                                    ),
                                  },
                                  onLinkTap: (url, context, attributes) {
                                    if (url != null) _launchUrl(url);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomHeader(
                title: 'promotions.details_title'.tr(),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
