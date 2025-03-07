import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/promotion_details_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/features/general/scanner/widgets/auth_warning_modal.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class PromotionDetailsPage extends ConsumerWidget {
  final int id;

  const PromotionDetailsPage({
    super.key,
    required this.id,
  });

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
                        child: SizedBox(
                          height: 240,
                          width: double.infinity,
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
                              const SizedBox(height: AppLength.sm),
                              if (promotion.type != 'DEFAULT')
                                CustomButton(
                                  label: 'promotions.scan_qr'.tr(),
                                  isFullWidth: true,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () {
                                    final authState = ref.read(authProvider);
                                    final mallId =
                                        promotion.building?.id.toString();

                                    if (mallId == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'promotions.error.no_mall'
                                                    .tr())),
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
                                      context.goNamed(
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
                              CustomButton(
                                button: promotion.button,
                                isFullWidth: true,
                                backgroundColor: AppColors.primary,
                              ),
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
