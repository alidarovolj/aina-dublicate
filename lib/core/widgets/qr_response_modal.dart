import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:easy_localization/easy_localization.dart';

class QrResponseModal extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final String? status;

  const QrResponseModal({
    super.key,
    required this.isSuccess,
    required this.message,
    this.status,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isSuccess,
    required String message,
    String? status,
  }) {
    return showDialog(
      context: context,
      builder: (context) => QrResponseModal(
        isSuccess: isSuccess,
        message: message,
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess ? 'qr.success'.tr() : 'qr.error'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textDarkGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDarkGrey,
              ),
              textAlign: TextAlign.start,
            ),
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(
                'qr.status'.tr(args: [status!]),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDarkGrey,
                ),
                textAlign: TextAlign.start,
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              label: 'qr.close'.tr(),
              onPressed: () => Navigator.of(context).pop(),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
