import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/utils/button_navigation_handler.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/types/button_config.dart';

enum ButtonType { normal, filled, bordered }

class CustomButton extends ConsumerWidget {
  final ButtonConfig? button;
  final String? label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool isEnabled;
  final ButtonType type;
  final bool isFullWidth;
  final Widget? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    this.button,
    this.label,
    this.onPressed,
    this.backgroundColor,
    this.width,
    this.height,
    this.isEnabled = true,
    this.type = ButtonType.normal,
    this.isFullWidth = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (button == null && label == null) return const SizedBox.shrink();

    final buttonLabel = button?.label ?? label ?? '';
    final buttonColor = button?.color ?? backgroundColor?.toString();

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: (!isEnabled || isLoading)
            ? null
            : (onPressed ??
                () {
                  if (button != null) {
                    ButtonNavigationHandler.handleNavigation(
                        context, ref, button);
                  }
                }),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(buttonColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: type == ButtonType.bordered
                ? const BorderSide(color: AppColors.primary)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getBackgroundColor(String? buttonColor) {
    if (!isEnabled) return AppColors.grey2;
    if (type == ButtonType.bordered) return Colors.white;
    if (buttonColor != null && buttonColor.startsWith('#')) {
      return Color(int.parse(buttonColor.replaceAll('#', '0xFF')));
    }
    return backgroundColor ?? AppColors.primary;
  }

  Color _getTextColor() {
    if (!isEnabled) return AppColors.grey2;
    if (type == ButtonType.bordered) return AppColors.primary;
    return Colors.white;
  }
}
