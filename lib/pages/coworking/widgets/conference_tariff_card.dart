import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/widgets/base_modal.dart';

class ConferenceTariffCard extends ConsumerWidget {
  final CoworkingTariff tariff;
  final VoidCallback? onDetailsTap;
  final int coworkingId;
  final int serviceId;

  const ConferenceTariffCard({
    super.key,
    required this.tariff,
    required this.coworkingId,
    required this.serviceId,
    this.onDetailsTap,
  });

  // Check only authentication without biometric verification
  Future<bool> checkAuth(BuildContext context, WidgetRef ref) async {
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

    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        // Only check authentication, not biometric
        if (await checkAuth(context, ref)) {
          context.pushNamed(
            'conference_room_details',
            pathParameters: {
              'id': coworkingId.toString(),
              'serviceId': serviceId.toString(),
              'tariffId': tariff.id.toString(),
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Stack(
          children: [
            if (tariff.image?.url != null && tariff.image!.url.isNotEmpty)
              Container(
                height: 240,
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
                height: 240,
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
              child: tariff.capacity != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                    )
                  : const SizedBox.shrink(),
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
