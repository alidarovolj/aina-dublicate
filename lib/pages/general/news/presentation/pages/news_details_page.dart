import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/news_details_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/widgets/custom_button.dart';
import 'package:aina_flutter/shared/types/button_config.dart';
import 'package:aina_flutter/widgets/base_slider.dart';
import 'package:aina_flutter/shared/types/slides.dart' as slides;
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/utils/button_navigation_handler.dart';

class NewsDetailsPage extends ConsumerWidget {
  final int id;

  const NewsDetailsPage({
    super.key,
    required this.id,
  });

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleButtonClick(
      BuildContext context, WidgetRef ref, ButtonConfig? button) {
    if (button == null) return;
    ButtonNavigationHandler.handleNavigation(context, ref, button);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsDetailsProvider(id.toString()));

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              newsAsync.when(
                loading: () => _buildSkeleton(),
                error: (error, stack) => Center(
                  child: Text('news.error'.tr(args: [error.toString()])),
                ),
                data: (news) => Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            news.previewImage.url,
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
                                news.title,
                                style: GoogleFonts.lora(
                                  fontSize: 24,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(height: AppLength.sm),
                              Html(
                                data: news.subtitle,
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
                              const SizedBox(height: AppLength.sm),
                              Html(
                                data: news.body,
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
                              if (news.images.isNotEmpty) ...[
                                const SizedBox(height: AppLength.sm),
                                CarouselWithIndicator(
                                  slideList: news.images
                                      .map((image) => slides.Slide(
                                            id: image.id,
                                            name: news.title,
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
                              if (news.button != null) ...[
                                const SizedBox(height: AppLength.sm),
                                CustomButton(
                                  button: ButtonConfig(
                                    label: news.button!.label,
                                    isInternal:
                                        news.button!.isInternal ?? false,
                                    internal: news.button!.internal != null
                                        ? ButtonInternal(
                                            model: news.button!.internal!.model,
                                            id: news.button!.internal!.id,
                                            buildingType: news
                                                .button!.internal!.buildingType,
                                            isAuthRequired: news.button!
                                                .internal!.isAuthRequired,
                                          )
                                        : null,
                                  ),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () => _handleButtonClick(
                                    context,
                                    ref,
                                    ButtonConfig(
                                      label: news.button!.label,
                                      isInternal:
                                          news.button!.isInternal ?? false,
                                      internal: news.button!.internal != null
                                          ? ButtonInternal(
                                              model:
                                                  news.button!.internal!.model,
                                              id: news.button!.internal!.id,
                                              buildingType: news.button!
                                                  .internal!.buildingType,
                                              isAuthRequired: news.button!
                                                  .internal!.isAuthRequired,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                              if (news.bottomBody != null &&
                                  news.bottomBody!.isNotEmpty) ...[
                                const SizedBox(height: AppLength.sm),
                                Html(
                                  data: news.bottomBody!,
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
                title: 'news.details_title'.tr(),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
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
                              )),
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
}
