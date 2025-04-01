import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';

class BaseTextarea extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? minLines;
  final void Function(String)? onChanged;

  const BaseTextarea({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.maxLines = 5,
    this.minLines = 5,
    this.onChanged,
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
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            hintStyle: const TextStyle(color: AppColors.grey2),
          ),
        ),
      ],
    );
  }
}
