import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/news_details_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/types/button_config.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/types/slides.dart' as slides;
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class NewsDetailsPage extends ConsumerWidget {
  final int id;

  const NewsDetailsPage({
    super.key,
    required this.id,
  });

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
                        child: SizedBox(
                          height: 240,
                          width: double.infinity,
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
                                  button: news.button != null
                                      ? ButtonConfig(
                                          label: news.button!.label,
                                          link: news.button!.link,
                                          isInternal: news.button!.isInternal,
                                        )
                                      : null,
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
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
