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
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/types/button_config.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';

class EventDetailsPage extends ConsumerWidget {
  final String id;
  final bool fromHome;

  const EventDetailsPage({
    super.key,
    required this.id,
    this.fromHome = false,
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
              child: Container(
                height: 240,
                width: double.infinity,
                color: Colors.white,
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
    final eventAsync = ref.watch(eventDetailsProvider(id));

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

                  return Container(
                    margin: const EdgeInsets.only(top: 64),
                    child: ErrorRefreshWidget(
                      onRefresh: () {
                        print('🔄 Refreshing event details...');
                        Future.microtask(() async {
                          try {
                            ref.refresh(eventDetailsProvider(id));
                          } catch (e) {
                            print('❌ Error refreshing event details: $e');
                          }
                        });
                      },
                      errorMessage: is500Error
                          ? 'events.error.server'.tr()
                          : 'events.error.loading'.tr(),
                      refreshText: 'common.refresh'.tr(),
                      icon: Icons.warning_amber_rounded,
                      isServerError: true,
                    ),
                  );
                },
                data: (event) => Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: Image.network(
                            event.previewImage.url,
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
                                event.title,
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
                                    event.formattedDateRange,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppLength.sm),
                              Html(
                                data: event.subtitle,
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
                                data: event.body,
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
                              if (event.button != null)
                                CustomButton(
                                  button: event.button != null
                                      ? ButtonConfig(
                                          label: event.button!.label,
                                          color: event.button!.color,
                                          isInternal: event.button!.isInternal,
                                          link: event.button!.link,
                                          internal:
                                              event.button!.internal != null
                                                  ? ButtonInternal(
                                                      model: event.button!
                                                          .internal!.model,
                                                      id: event
                                                          .button!.internal!.id,
                                                      buildingType: event
                                                          .button!
                                                          .internal!
                                                          .buildingType,
                                                      isAuthRequired: event
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
                              if (event.bottomBody != null &&
                                  event.bottomBody!.isNotEmpty) ...[
                                const SizedBox(height: AppLength.sm),
                                Html(
                                  data: event.bottomBody!,
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
