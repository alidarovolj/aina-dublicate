import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/widgets/base_modal.dart';
import 'package:aina_flutter/app/providers/requests/auth/profile.dart'
    as profile;

mixin AuthCheckMixin {
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'ru_RU');
    return formatter.format(price).replaceAll(',', ' ');
  }

  Future<bool> checkAuthAndBiometric(
      BuildContext context, WidgetRef ref, int coworkingId) async {
    final authState = ref.read(authProvider);
    final isAuthorized = authState.isAuthenticated;

    if (!isAuthorized) {
      BaseModal.show(
        context,
        message: 'auth.service_auth_required'.tr(),
        buttons: [
          ModalButton(
            label: 'auth.register'.tr(),
            onPressed: () {
              context.pop();
              context.pushNamed('login');
            },
          ),
        ],
      );
      return false;
    }

    try {
      // Get fresh profile data
      final profileService = ref.read(profile.promenadeProfileProvider);
      final profileData = await profileService.getProfile(forceRefresh: true);

      if (profileData['biometric_valid'] != true ||
          profileData['biometric_status'] != 'VALID') {
        BaseModal.show(
          context,
          message: 'auth.service_biometric_required'.tr(),
          buttons: [
            ModalButton(
              label: 'auth.verify_biometric'.tr(),
              onPressed: () {
                context.pop();
                context.push('/coworking/$coworkingId/profile/biometric');
              },
            ),
          ],
        );
        return false;
      }
    } catch (e) {
      return false;
    }

    return true;
  }
}

class ConferenceTariffCard extends ConsumerWidget with AuthCheckMixin {
  final CoworkingTariff tariff;
  final int coworkingId;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsTap;

  const ConferenceTariffCard({
    super.key,
    required this.tariff,
    required this.coworkingId,
    this.onTap,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        if (await checkAuthAndBiometric(context, ref, coworkingId)) {
          onTap?.call();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: Stack(
          children: [
            if (tariff.image?.url != null && tariff.image!.url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(tariff.image!.url),
                        fit: BoxFit.cover,
                      ),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 48),
                    ),
                  ),
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
                  'coworking.tariffs.capacity'
                      .tr(args: [tariff.capacity.toString()]),
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
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'coworking.tariffs.price_per_hour'
                        .tr(args: [formatPrice(tariff.price)]),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
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

class TariffCard extends ConsumerWidget with AuthCheckMixin {
  final CoworkingTariff tariff;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsTap;
  final int coworkingId;

  const TariffCard({
    super.key,
    required this.tariff,
    required this.coworkingId,
    this.onTap,
    this.onDetailsTap,
  });

  void _showTariffDetails(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: (MediaQuery.of(context).size.width -
                  (MediaQuery.of(context).size.width - 32)) /
              2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tariff.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Html(
                data: tariff.description,
                style: {
                  "body": Style(
                    color: AppColors.primary,
                    fontSize: FontSize(16),
                    margin: Margins.zero,
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 4),
                  ),
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          if (await checkAuthAndBiometric(
                              dialogContext, ref, coworkingId)) {
                            // Закрываем диалог перед навигацией
                            Navigator.of(dialogContext).pop();
                            _navigateToCalendar(context, ref);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                          ),
                          child: Text(
                            '${formatPrice(tariff.price)} тг',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        if (await checkAuthAndBiometric(
                            dialogContext, ref, coworkingId)) {
                          // Закрываем диалог перед навигацией
                          Navigator.of(dialogContext).pop();
                          _navigateToCalendar(context, ref);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: SvgPicture.asset(
                          'lib/app/assets/icons/linked-arrow.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCalendar(BuildContext context, WidgetRef ref) {
    context.pushNamed(
      'coworking_calendar',
      pathParameters: {
        'id': coworkingId.toString(),
        'tariffId': tariff.id.toString(),
      },
      queryParameters: {
        'type': tariff.type.toLowerCase(),
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tariff.type == 'COWORKING') {
      return _buildCoworkingTariffCard(context, ref);
    }
    return ConferenceTariffCard(
      tariff: tariff,
      coworkingId: coworkingId,
      onTap: () => _navigateToCalendar(context, ref),
      onDetailsTap: onDetailsTap,
    );
  }

  Widget _buildCoworkingTariffCard(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 260,
      ),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  tariff.image?.url ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                if (await checkAuthAndBiometric(context, ref, coworkingId)) {
                  onTap?.call();
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tariff.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                            color: AppColors.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tariff.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tariff.isFixed
                              ? 'coworking.tariffs.fixed_place'.tr()
                              : 'coworking.tariffs.unfixed_place'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDarkGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => _showTariffDetails(context, ref),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'coworking.tariffs.all_benefits'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (await checkAuthAndBiometric(
                                  context, ref, coworkingId)) {
                                _navigateToCalendar(context, ref);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Text(
                                '${formatPrice(tariff.price)} тг',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            if (await checkAuthAndBiometric(
                                context, ref, coworkingId)) {
                              _navigateToCalendar(context, ref);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: SvgPicture.asset(
                              'lib/app/assets/icons/linked-arrow.svg',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
