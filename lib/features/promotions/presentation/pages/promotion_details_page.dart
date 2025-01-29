import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/promotion_details_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/features/scanner/widgets/auth_warning_modal.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';

class PromotionDetailsPage extends ConsumerWidget {
  final int id;

  const PromotionDetailsPage({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionAsync = ref.watch(promotionDetailsProvider(id.toString()));

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.white,
                margin: const EdgeInsets.only(top: 64),
                child: promotionAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppLength.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (promotion) => CustomScrollView(
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
                              CustomButton(
                                label: 'Сканировать QR код',
                                isFullWidth: true,
                                backgroundColor: AppColors.primary,
                                onPressed: () {
                                  final authState = ref.read(authProvider);
                                  final mallId =
                                      promotion.building?.id.toString();
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
                                    context.push(
                                      '/malls/$mallId/promotions/${promotion.id}/qr',
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
              const CustomHeader(
                title: 'Акция',
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
