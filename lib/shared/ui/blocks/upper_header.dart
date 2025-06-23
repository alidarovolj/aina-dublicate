import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/language_switcher.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/features/user/ui/widgets/simple_auth_warning_modal.dart';

class UpperHeader extends ConsumerStatefulWidget {
  const UpperHeader({super.key});

  @override
  ConsumerState<UpperHeader> createState() => _UpperHeaderState();
}

class _UpperHeaderState extends ConsumerState<UpperHeader> {
  bool _isValidatingToken = false;

  @override
  Widget build(BuildContext context) {
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
                      onTap: _isValidatingToken
                          ? null
                          : () async {
                              final authState = ref.read(authProvider);
                              if (!authState.isAuthenticated) {
                                // Show auth warning modal if not authenticated
                                SimpleAuthWarningModal.show(context);
                                return;
                              }

                              // Show loading state
                              setState(() {
                                _isValidatingToken = true;
                              });

                              try {
                                // Validate token before proceeding
                                final authNotifier =
                                    ref.read(authProvider.notifier);
                                final isTokenValid =
                                    await authNotifier.validateToken();

                                if (!isTokenValid) {
                                  // Token is invalid or expired, show auth modal
                                  if (context.mounted) {
                                    SimpleAuthWarningModal.show(context);
                                  }
                                  return;
                                }

                                // Token is valid, proceed to QR scan
                                if (context.mounted) {
                                  context.pushNamed('auth_qr_scan');
                                }
                              } finally {
                                // Hide loading state
                                if (mounted) {
                                  setState(() {
                                    _isValidatingToken = false;
                                  });
                                }
                              }
                            },
                      child: _isValidatingToken
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : SvgPicture.asset(
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
