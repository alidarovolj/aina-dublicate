import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';

class GenderSelector extends ConsumerWidget {
  final String selectedGender;
  final Function(String) onChanged;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  Widget _buildGenderOption(
      String value, String groupValue, Function(String) onChanged) {
    final isSelected = value == groupValue;

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
              activeColor: AppColors.primary,
              fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textDarkGrey;
              }),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primary : AppColors.textDarkGrey,
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
          'profile.settings.edit.gender.title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDarkGrey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: _buildGenderOption(
                'profile.settings.edit.gender.female'.tr(),
                selectedGender,
                onChanged,
              ),
            ),
            Expanded(
              child: _buildGenderOption(
                'profile.settings.edit.gender.male'.tr(),
                selectedGender,
                onChanged,
              ),
            ),
            Expanded(
              child: _buildGenderOption(
                'profile.settings.edit.gender.not_specified'.tr(),
                selectedGender,
                onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
