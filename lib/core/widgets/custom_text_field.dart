import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final TextCapitalization textCapitalization;
  final bool? isValid;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final IconData? suffixIcon;
  final Color? suffixIconColor;
  final Widget? prefixIconWidget;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
    this.isValid,
    this.prefixIcon,
    this.prefixIconColor,
    this.suffixIcon,
    this.suffixIconColor,
    this.prefixIconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: enabled ? AppColors.primary : Colors.grey[500],
      ),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        suffixIcon: isValid == null
            ? suffix
            : Icon(
                isValid! ? Icons.check_circle : Icons.error,
                color: isValid! ? Colors.green : Colors.red,
              ),
        prefixIcon: prefixIconWidget != null
            ? SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(
                      color: enabled ? null : Colors.grey[500],
                    ),
                    child: prefixIconWidget!,
                  ),
                ),
              )
            : (prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: enabled
                        ? prefixIconColor ?? Colors.grey[600]
                        : Colors.grey[500],
                    size: 20,
                  )
                : null),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: AppColors.darkGrey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isValid == null
                ? AppColors.darkGrey
                : isValid!
                    ? Colors.green
                    : Colors.red,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isValid == null
                ? Colors.blue
                : isValid!
                    ? Colors.green
                    : Colors.red,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: AppColors.darkGrey,
          ),
        ),
      ),
    );
  }
}
