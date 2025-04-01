import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class ReceiptErrorModal {
  static Future<void> show(
    BuildContext context, {
    required String message,
    required String mallId,
  }) {
    return BaseModal.show(
      context,
      title: 'receipt.error'.tr(),
      message: message,
      buttons: [
        ModalButton(
          label: 'receipt.back_to_promotions'.tr(),
          onPressed: () {
            context.push('/malls/$mallId/promotions');
          },
          textColor: AppColors.secondary,
          backgroundColor: Colors.white,
        ),
        ModalButton(
          label: 'receipt.scan_again'.tr(),
          type: ButtonType.light,
        ),
      ],
    );
  }
}
