import 'package:flutter/material.dart';

class CustomButtonData {
  final String label; // Text on the button
  final VoidCallback onPressed; // Action on press
  final Color? color; // Button color (optional)
  final double? width; // Button width (optional)
  final double? height; // Button height (optional)
  final TextStyle? textStyle; // Text style (optional)
  final Widget? icon; // Icon or any widget (optional)

  const CustomButtonData({
    required this.label,
    required this.onPressed,
    this.color,
    this.width,
    this.height,
    this.textStyle,
    this.icon,
  });
}
