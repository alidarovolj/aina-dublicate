import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';

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
          activeColor: Colors.white,
          activeTrackColor: activeColor ?? AppColors.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[300],
          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey[400];
            }
            return Colors.transparent;
          }),
        ),
      ],
    );
  }
}
