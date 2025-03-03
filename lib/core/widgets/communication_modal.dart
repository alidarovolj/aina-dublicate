import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';
import 'package:aina_flutter/core/widgets/feedback_form_modal.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';

class CommunicationModal {
  static Future<void> show(
    BuildContext context, {
    required String whatsappUrl,
    bool onlyWhatsapp = false,
    VoidCallback? onCreateRequest,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.9;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: (screenWidth - dialogWidth) / 2,
        ),
        child: Consumer(
          builder: (context, ref, child) {
            final settingsAsync = ref.watch(settingsProvider);
            final authState = ref.read(authProvider);

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'communication.modal.title'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDarkGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  settingsAsync.when(
                    data: (settings) => _buildWhatsAppButton(
                      context,
                      settings.whatsappLinkPromenade,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) =>
                        _buildWhatsAppButton(context, whatsappUrl),
                  ),
                  _buildDescription(
                      'communication.modal.whatsapp.description'.tr()),
                  if (!onlyWhatsapp) ...[
                    const SizedBox(height: 28),
                    _buildRequestButton(context, ref),
                    _buildDescription(
                        'communication.modal.create_request.description'.tr()),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildWhatsAppButton(BuildContext context, String whatsappUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CustomButton(
        label: 'communication.modal.whatsapp.button_text'.tr(),
        onPressed: () async {
          try {
            // Декодируем URL и заменяем закодированные символы
            final decodedUrl = Uri.decodeFull(whatsappUrl)
                .replaceAll('%2B', '+')
                .replaceAll('%20', ' ');

            // Пробуем сначала открыть через whatsapp://
            final whatsappUri = Uri.parse(decodedUrl.replaceAll(
              'https://api.whatsapp.com/send',
              'whatsapp://send',
            ));

            bool launched = false;
            try {
              launched = await launchUrl(
                whatsappUri,
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {
              launched = false;
            }

            // Если не получилось открыть через whatsapp://, пробуем через https://
            if (!launched) {
              final httpUri = Uri.parse(decodedUrl);
              launched = await launchUrl(
                httpUri,
                mode: LaunchMode.externalApplication,
              );
            }

            if (!launched && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('communication.modal.whatsapp.error'.tr()),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('communication.modal.whatsapp.error'.tr()),
                ),
              );
            }
          }
        },
        type: ButtonType.bordered,
        isFullWidth: true,
        backgroundColor: AppColors.appBg,
        icon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SvgPicture.asset(
            'lib/core/assets/icons/whatsapp.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  static Widget _buildRequestButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CustomButton(
        label: 'communication.modal.create_request.button_text'.tr(),
        onPressed: () {
          final authState = ref.read(authProvider);
          String? phone;
          if (authState.userData != null) {
            try {
              final userData = UserProfile.fromJson(authState.userData!);
              phone = userData.maskedPhone;
            } catch (e) {
              // If there's an error parsing user data, we'll proceed without the phone
              // print('Error loading user phone: $e');
            }
          }
          Navigator.of(context).pop();
          FeedbackFormModal.show(context);
        },
        type: ButtonType.filled,
        isFullWidth: true,
      ),
    );
  }

  static Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textDarkGrey,
        ),
      ),
    );
  }
}
