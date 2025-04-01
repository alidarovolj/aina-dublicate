import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';

class MallDetailsHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const MallDetailsHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(
        horizontal: AppLength.xs,
        vertical: AppLength.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
