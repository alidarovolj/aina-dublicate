import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/event_details_provider.dart';
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
import 'package:aina_flutter/core/types/button_config.dart';

class EventDetailsPage extends ConsumerWidget {
  final int id;

  const EventDetailsPage({
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
                        ),
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
                        ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailsProvider(id.toString()));

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              eventAsync.when(
                loading: () => _buildSkeleton(),
                error: (error, stack) {
                  print('❌ Error loading event details: $error');

                  final is500Error = error.toString().contains('500') ||
                      error.toString().contains('Internal Server Error');
                  final isNotFoundError =
                      error.toString().contains('Event not found');

                  return Container(
                    margin: const EdgeInsets.only(top: 64),
                    child: ErrorRefreshWidget(
                      onRefresh: () {
                        print('🔄 Refreshing event details...');
                        Future.microtask(() async {
                          try {
                            ref.refresh(eventDetailsProvider(id.toString()));
                          } catch (e) {
                            print('❌ Error refreshing event details: $e');
                          }
                        });
                      },
                      errorMessage: isNotFoundError
                          ? 'events.error.not_found'.tr()
                          : is500Error
                              ? 'events.error.server'.tr()
                              : 'events.error.loading'.tr(),
                      refreshText: 'common.refresh'.tr(),
                      icon: isNotFoundError
                          ? Icons.search_off_rounded
                          : Icons.warning_amber_rounded,
                      isServerError: is500Error,
                    ),
                  );
                },
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
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.textDarkGrey,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: AppLength.xs),
                                  Text(
                                    promotion.formattedDateRange,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                ],
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
                                },
                              ),
                              if (promotion.button != null) ...[
                                const SizedBox(height: AppLength.sm),
                                CustomButton(
                                  button: ButtonConfig(
                                    label: promotion.button!.label,
                                    isInternal: promotion.button!.isInternal,
                                    internal: promotion.button!.internal != null
                                        ? ButtonInternal(
                                            model: promotion
                                                .button!.internal!.model,
                                            id: promotion.button!.internal!.id,
                                            buildingType: promotion
                                                .button!.internal!.buildingType,
                                            isAuthRequired: promotion.button!
                                                .internal!.isAuthRequired,
                                          )
                                        : null,
                                  ),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                ),
                              ],
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
                                },
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
                title: 'events.details_title'.tr(),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
