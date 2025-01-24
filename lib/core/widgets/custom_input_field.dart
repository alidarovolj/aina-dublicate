import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final String? hintText;
  final String? placeholder;
  final FocusNode? focusNode;
  final Function(String)? onChanged; // Add this line

  const CustomInputField({
    super.key,
    this.label = '',
    required this.controller,
    this.isRequired = false,
    this.hintText,
    this.placeholder,
    this.focusNode,
    this.onChanged, // Add this line
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
          decoration: InputDecoration(
            hintText: placeholder ?? hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorText: isRequired && controller.text.isEmpty
                ? 'Это обязательное поле'
                : null,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
