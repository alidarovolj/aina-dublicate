import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final String? hintText;
  final String? placeholder;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final bool hasError;
  final String? errorText;

  const CustomInputField({
    super.key,
    this.label = '',
    required this.controller,
    this.isRequired = false,
    this.hintText,
    this.placeholder,
    this.focusNode,
    this.onChanged,
    this.hasError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(
            color: AppColors.textDarkGrey,
          ),
          decoration: InputDecoration(
            hintText: placeholder ?? hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.lightGrey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.lightGrey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.primary,
              ),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorText: hasError ? errorText : null,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
