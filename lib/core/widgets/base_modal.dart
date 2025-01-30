import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';

class BaseModal extends StatelessWidget {
  final String? title;
  final String message;
  final List<ModalButton> buttons;
  final EdgeInsets? padding;
  final CrossAxisAlignment? crossAxisAlignment;
  final bool barrierDismissible;
  final double? width;

  const BaseModal({
    super.key,
    this.title,
    required this.message,
    required this.buttons,
    this.padding,
    this.crossAxisAlignment,
    this.barrierDismissible = false,
    this.width,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    required String message,
    required List<ModalButton> buttons,
    EdgeInsets? padding,
    CrossAxisAlignment? crossAxisAlignment,
    bool barrierDismissible = false,
    double? width,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => BaseModal(
        title: title,
        message: message,
        buttons: buttons,
        padding: padding,
        crossAxisAlignment: crossAxisAlignment,
        barrierDismissible: barrierDismissible,
        width: width ?? MediaQuery.of(context).size.width - 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.appBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: width != null
          ? EdgeInsets.symmetric(
              horizontal: (MediaQuery.of(context).size.width - width!) / 2)
          : const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDarkGrey,
                ),
              ),
            if (title != null) const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDarkGrey,
              ),
            ),
            const SizedBox(height: 24),
            if (buttons.length == 1)
              CustomButton(
                label: buttons[0].label,
                size: ButtonSize.small,
                type: buttons[0].type,
                onPressed: () {
                  Navigator.of(context).pop();
                  buttons[0].onPressed?.call();
                },
                textColor: buttons[0].textColor,
                backgroundColor: buttons[0].backgroundColor,
                isFullWidth: true,
              )
            else
              Row(
                children: buttons.map((button) {
                  final isLast = buttons.last == button;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: button.label,
                            size: ButtonSize.small,
                            type: button.type,
                            onPressed: () {
                              Navigator.of(context).pop();
                              button.onPressed?.call();
                            },
                            textColor: button.textColor,
                            backgroundColor: button.backgroundColor,
                          ),
                        ),
                        if (!isLast) const SizedBox(width: 12),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class ModalButton {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final Color? textColor;
  final Color? backgroundColor;

  const ModalButton({
    required this.label,
    this.onPressed,
    this.type = ButtonType.normal,
    this.textColor,
    this.backgroundColor,
  });
}
