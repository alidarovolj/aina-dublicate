import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';

class TariffsModal extends StatelessWidget {
  final VoidCallback onClose;

  const TariffsModal({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'biometry.success'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('biometry.tariffs_description'.tr()),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: () {
                onClose();
                context.push('/tariffs');
              },
              label: 'biometry.view_tariffs'.tr(),
              isFullWidth: true,
            ),
            const SizedBox(height: 12),
            CustomButton(
              onPressed: onClose,
              label: 'common.close'.tr(),
              type: ButtonType.bordered,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
