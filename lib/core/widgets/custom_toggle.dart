import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';

class CustomToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final Color? activeColor;

  const CustomToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor ?? AppColors.primary,
          activeTrackColor: activeColor?.withOpacity(0.4) ??
              AppColors.primary.withOpacity(0.4),
        ),
      ],
    );
  }
}
