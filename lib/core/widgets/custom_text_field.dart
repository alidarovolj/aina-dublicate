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
      style: const TextStyle(color: AppColors.primary),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        suffixIcon: isValid == null
            ? suffix
            : Icon(
                isValid! ? Icons.check_circle : Icons.error,
                color: isValid! ? Colors.green : Colors.red,
              ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isValid == null
                ? Colors.grey[300]!
                : isValid!
                    ? Colors.green
                    : Colors.red,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isValid == null
                ? Colors.blue
                : isValid!
                    ? Colors.green
                    : Colors.red,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
      ),
    );
  }
}
