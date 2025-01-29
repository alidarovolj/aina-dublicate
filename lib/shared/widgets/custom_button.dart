import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/utils/button_navigation_handler.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/types/button_config.dart';

enum ButtonType { normal, filled, bordered, light }

enum ButtonSize { small, normal, big }

class CustomButton extends ConsumerWidget {
  final ButtonConfig? button;
  final String? label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool isEnabled;
  final ButtonType type;
  final ButtonSize size;
  final bool isFullWidth;
  final Widget? icon;
  final bool isLoading;
  final Color? textColor;

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
    this.size = ButtonSize.normal,
    this.isFullWidth = false,
    this.icon,
    this.isLoading = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (button == null && label == null) return const SizedBox.shrink();

    final buttonLabel = button?.label ?? label ?? '';
    final buttonColor = button?.color ?? backgroundColor?.toString();

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: _getHeight(),
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
          padding: _getPadding(),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
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
                  Flexible(
                    child: Text(
                      buttonLabel,
                      style: TextStyle(
                        color: textColor ?? _getTextColor(),
                        fontSize: _getFontSize(),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.normal:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.big:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.normal:
        return 16;
      case ButtonSize.big:
        return 18;
    }
  }

  double _getHeight() {
    if (height != null) return height!;
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.normal:
        return 48;
      case ButtonSize.big:
        return 56;
    }
  }

  Color _getBackgroundColor(String? buttonColor) {
    if (!isEnabled) return AppColors.grey2;
    if (type == ButtonType.bordered) return Colors.white;
    if (buttonColor != null && buttonColor.startsWith('#')) {
      return Color(int.parse(buttonColor.replaceAll('#', '0xFF')));
    }
    if (type == ButtonType.light) return AppColors.lightGrey;
    return backgroundColor ?? AppColors.primary;
  }

  Color _getTextColor() {
    if (!isEnabled) return AppColors.grey2;
    if (type == ButtonType.bordered) return AppColors.primary;
    if (type == ButtonType.light) return AppColors.primary;
    return Colors.white;
  }
}
