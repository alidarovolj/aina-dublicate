import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/language_switcher.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/features/user/ui/widgets/simple_auth_warning_modal.dart';

class UpperHeader extends ConsumerWidget {
  const UpperHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: AppLength.xxl),
          color: AppColors.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppLength.xl),
                child: SvgPicture.asset(
                  'lib/app/assets/images/logo-short.svg',
                  height: 17,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(right: AppLength.sm),
                    child: const LanguageSwitcher(),
                  ),
                  const SizedBox(width: AppLength.tiny),
                  Container(
                    padding: const EdgeInsets.only(right: AppLength.xl),
                    child: GestureDetector(
                      onTap: () {
                        final authState = ref.read(authProvider);
                        if (!authState.isAuthenticated) {
                          // Show auth warning modal if not authenticated
                          SimpleAuthWarningModal.show(context);
                        } else {
                          // User is authenticated, navigate to QR scan
                          context.pushNamed('auth_qr_scan');
                        }
                      },
                      child: SvgPicture.asset(
                        'lib/app/assets/icons/qr_scan.svg',
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
