import 'package:flutter/material.dart';

class CommunityCardStyles {
  static const double borderRadius = 4.0;
  static const double spacing = 16.0;
  static const double avatarSize = 80.0;
  static const double iconSize = 40.0;

  static const Color goldAccent = Color(0xFFD4B33E);
  static const Color backgroundGrey = Color(0xFFECECEC);
  static const Color textGrey = Color(0xFF8E8E93);
  static const Color dividerColor = Color(0xFFD1D1D6);

  static const TextStyle headerText = TextStyle(
    fontSize: 14,
    color: textGrey,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle helperText = TextStyle(
    fontSize: 12,
    color: textGrey,
  );

  static BoxDecoration avatarDecoration = BoxDecoration(
    color: goldAccent,
    borderRadius: BorderRadius.circular(borderRadius),
  );

  static BoxDecoration imageInputDecoration = BoxDecoration(
    color: backgroundGrey,
    borderRadius: BorderRadius.circular(borderRadius),
  );

  static BoxDecoration statusDecoration = const BoxDecoration(
    color: backgroundGrey,
    border: Border(
      bottom: BorderSide(
        color: dividerColor,
        width: 1,
      ),
    ),
  );
}
