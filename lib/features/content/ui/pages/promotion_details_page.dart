import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/promotion_details_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:aina_flutter/shared/ui/widgets/base_slider.dart';
import 'package:aina_flutter/shared/types/slides.dart' as slides;
import 'package:aina_flutter/features/user/ui/widgets/auth_warning_modal.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';
import 'package:aina_flutter/shared/types/button_config.dart';
import 'package:aina_flutter/shared/types/promotion.dart';
import 'package:aina_flutter/app/providers/requests/auth/profile.dart';

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
                                    'lib/app/assets/icons/calendar.svg',
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
                                      _launchUrl(promotion.file!.url);
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'promotions.view_terms'.tr(),
                                        style: const TextStyle(
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
                                  onPressed: () async {
                                    AmplitudeService().logEvent(
                                      'scan_pageinfo_click',
                                      eventProperties: {
                                        'Platform': _getPlatform(),
                                      },
                                    );

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

                                    // Проверяем авторизацию и получаем профиль пользователя
                                    final authState = ref.read(authProvider);
                                    if (!authState.isAuthenticated) {
                                      // Пользователь не авторизован, показываем модальное окно авторизации
                                      AuthWarningModal.show(
                                        context,
                                        promotionId: id.toString(),
                                        mallId: mallId,
                                      );
                                      return;
                                    }

                                    // Пользователь авторизован, делаем запрос на получение профиля
                                    try {
                                      final profileService =
                                          ref.read(promenadeProfileProvider);
                                      final profileData = await profileService
                                          .getProfile(forceRefresh: true);

                                      // Проверяем наличие имени и фамилии
                                      final firstName =
                                          profileData['firstname'];
                                      final lastName = profileData['lastname'];

                                      final hasNameInfo = firstName != null &&
                                          firstName
                                              .toString()
                                              .trim()
                                              .isNotEmpty &&
                                          lastName != null &&
                                          lastName.toString().trim().isNotEmpty;

                                      if (hasNameInfo) {
                                        // Имя и фамилия указаны, переходим сразу к QR-сканеру
                                        if (context.mounted) {
                                          context.pushNamed(
                                            'promotion_qr',
                                            pathParameters: {
                                              'promotionId': id.toString(),
                                            },
                                            queryParameters: {
                                              'mallId': mallId,
                                            },
                                          );
                                        }
                                      } else {
                                        // Имя или фамилия не указаны, показываем предупреждение
                                        if (context.mounted) {
                                          AuthWarningModal.show(
                                            context,
                                            isProfileIncomplete: true,
                                            promotionId: id.toString(),
                                            mallId: mallId,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      // Обработка ошибок, включая 401 (Unauthorized)
                                      if (e.toString().contains('401')) {
                                        if (context.mounted) {
                                          AuthWarningModal.show(
                                            context,
                                            promotionId: id.toString(),
                                            mallId: mallId,
                                          );
                                        }
                                      } else {
                                        // Другая ошибка при получении профиля
                                        if (context.mounted) {
                                          BaseSnackBar.show(
                                            context,
                                            message:
                                                'common.error.general'.tr(),
                                            type: SnackBarType.error,
                                          );
                                        }
                                      }
                                    }
                                  },
                                )
                              else if (promotion.type == 'SERVICE_PURCHASE')
                                CustomButton(
                                  label: 'coworking.tariffs.title'.tr(),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () {
                                    if (promotion.building?.id != null) {
                                      context.pushReplacementNamed(
                                        'coworking_services',
                                        pathParameters: {
                                          'id':
                                              promotion.building!.id.toString(),
                                        },
                                      );
                                    } else {
                                      debugPrint('ERROR: Building ID is null');
                                    }
                                  },
                                )
                              else if (promotion.type == 'RAFFLE' &&
                                  promotion.isQr)
                                CustomButton(
                                  label: 'promotions.scan_qr'.tr(),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () async {
                                    AmplitudeService().logEvent(
                                      'scan_pageinfo_click',
                                      eventProperties: {
                                        'Platform': _getPlatform(),
                                      },
                                    );

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

                                    // Проверяем авторизацию и получаем профиль пользователя
                                    final authState = ref.read(authProvider);
                                    if (!authState.isAuthenticated) {
                                      // Пользователь не авторизован, показываем модальное окно авторизации
                                      AuthWarningModal.show(
                                        context,
                                        promotionId: id.toString(),
                                        mallId: mallId,
                                      );
                                      return;
                                    }

                                    // Пользователь авторизован, делаем запрос на получение профиля
                                    try {
                                      final profileService =
                                          ref.read(promenadeProfileProvider);
                                      final profileData = await profileService
                                          .getProfile(forceRefresh: true);

                                      // Проверяем наличие имени и фамилии
                                      final firstName =
                                          profileData['firstname'];
                                      final lastName = profileData['lastname'];

                                      final hasNameInfo = firstName != null &&
                                          firstName
                                              .toString()
                                              .trim()
                                              .isNotEmpty &&
                                          lastName != null &&
                                          lastName.toString().trim().isNotEmpty;

                                      if (hasNameInfo) {
                                        // Имя и фамилия указаны, переходим сразу к QR-сканеру
                                        if (context.mounted) {
                                          context.pushNamed(
                                            'promotion_qr',
                                            pathParameters: {
                                              'promotionId': id.toString(),
                                            },
                                            queryParameters: {
                                              'mallId': mallId,
                                            },
                                          );
                                        }
                                      } else {
                                        // Имя или фамилия не указаны, показываем предупреждение
                                        if (context.mounted) {
                                          AuthWarningModal.show(
                                            context,
                                            isProfileIncomplete: true,
                                            promotionId: id.toString(),
                                            mallId: mallId,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      // Обработка ошибок, включая 401 (Unauthorized)
                                      if (e.toString().contains('401')) {
                                        if (context.mounted) {
                                          AuthWarningModal.show(
                                            context,
                                            promotionId: id.toString(),
                                            mallId: mallId,
                                          );
                                        }
                                      } else {
                                        // Другая ошибка при получении профиля
                                        if (context.mounted) {
                                          BaseSnackBar.show(
                                            context,
                                            message:
                                                'common.error.general'.tr(),
                                            type: SnackBarType.error,
                                          );
                                        }
                                      }
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
                                                    buildId: promotion.button!.internal!.buildId,
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
