import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_svg/svg.dart';

class MallInfoBlock extends StatelessWidget {
  final String workingHours;
  final String address;
  final VoidCallback onCallTap;
  final VoidCallback onMapTap;

  const MallInfoBlock({
    super.key,
    required this.workingHours,
    required this.address,
    required this.onCallTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.appBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Working hours
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
            child: Column(
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'lib/app/assets/icons/time.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      workingHours,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Address
                Row(
                  children: [
                    SvgPicture.asset(
                      'lib/app/assets/icons/location.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Actions
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    onTap: onCallTap,
                    icon: SvgPicture.asset(
                      'lib/app/assets/icons/phone.svg',
                      width: 20,
                      height: 20,
                    ),
                    label: 'Позвонить',
                    fontSize: 14,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.black12,
                ),
                Expanded(
                  child: _ActionButton(
                    onTap: onMapTap,
                    icon: SvgPicture.asset(
                      'lib/app/assets/icons/location.svg',
                      width: 20,
                      height: 20,
                    ),
                    label: 'На карте',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final double fontSize;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: AppLength.xs),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black12),
              bottom: BorderSide(color: Colors.black12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
