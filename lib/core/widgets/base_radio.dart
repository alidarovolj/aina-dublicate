import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';

class BaseRadio extends ConsumerWidget {
  final String title;
  final String selectedValue;
  final List<String> options;
  final Function(String) onChanged;

  const BaseRadio({
    super.key,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  Widget _buildOption(
      String value, String groupValue, Function(String) onChanged) {
    final isSelected = value == groupValue;
    String displayText = value;

    // Translate gender values
    switch (value) {
      case 'MALE':
        displayText = 'profile.settings.edit.gender.male'.tr();
        break;
      case 'FEMALE':
        displayText = 'profile.settings.edit.gender.female'.tr();
        break;
      case 'NONE':
        displayText = 'profile.settings.edit.gender.not_specified'.tr();
        break;
    }

    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (value) => onChanged(value!),
              activeColor: AppColors.secondary,
              fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.secondary;
                }
                return AppColors.textDarkGrey;
              }),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color:
                    isSelected ? AppColors.secondary : AppColors.textDarkGrey,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDarkGrey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: options
              .map((option) => Expanded(
                    child: _buildOption(
                      option,
                      selectedValue,
                      onChanged,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
