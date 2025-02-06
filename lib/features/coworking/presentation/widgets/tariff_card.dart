import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/conference_tariff_card.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/app.dart';

mixin AuthCheckMixin {
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
      final promenadeProfileAsync =
          await ref.read(promenadeProfileProvider.future);
      if (!promenadeProfileAsync.isBiometricVerified) {
        BaseModal.show(
          context,
          message: 'auth.service_biometric_required'.tr(),
          buttons: [
            ModalButton(
              label: 'auth.verify_biometric'.tr(),
              onPressed: () {
                context.pop();
                context.go('/coworking/$coworkingId/profile/biometric');
              },
            ),
          ],
        );
        return false;
      }
    } catch (e) {
      print('Error checking biometric status: $e');
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
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            if (tariff.image?.url != null && tariff.image!.url.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(tariff.image!.url),
                    fit: BoxFit.cover,
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 48),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'coworking.tariffs.price_per_hour'
                        .tr(args: [tariff.price.toString()]),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
      builder: (context) => Dialog(
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
                              context, ref, coworkingId)) {
                            context.pop();
                            onTap?.call();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${tariff.price}₸',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.black,
                        size: 20,
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

  void _navigateToCalendar(BuildContext context, WidgetRef ref) async {
    if (await checkAuthAndBiometric(context, ref, coworkingId)) {
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  tariff.image?.url ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            InkWell(
              onTap: () async {
                if (await checkAuthAndBiometric(context, ref, coworkingId)) {
                  onTap?.call();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tariff.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tariff.subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tariff.isFixed
                          ? 'coworking.tariffs.fixed_place'.tr()
                          : 'coworking.tariffs.unfixed_place'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _showTariffDetails(context, ref),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
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
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _navigateToCalendar(context, ref),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${tariff.price}₸',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                            size: 20,
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
