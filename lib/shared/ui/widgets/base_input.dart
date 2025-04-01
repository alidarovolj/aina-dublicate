import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';

class BaseInput extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLength;

  const BaseInput({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDarkGrey,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            hintStyle: const TextStyle(color: AppColors.grey2),
            prefixIcon: prefix,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
