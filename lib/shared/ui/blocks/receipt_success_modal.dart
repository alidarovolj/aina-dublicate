import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class ReceiptSuccessModal {
  static Future<void> show(
    BuildContext context, {
    required double amount,
    required List<int> tickets,
    required String mallId,
  }) {
    return BaseModal.show(
      context,
      title: 'receipt.success_title'.tr(),
      message: 'receipt.success_message'.tr(args: [tickets.join(", ")]),
      width: MediaQuery.of(context).size.width,
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
          label: 'receipt.to_profile'.tr(),
          type: ButtonType.light,
          onPressed: () {
            context.push('/malls/$mallId/profile');
          },
        ),
      ],
    );
  }
}
