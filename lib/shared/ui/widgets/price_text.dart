import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceText extends StatelessWidget {
  final String price;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final bool withPerHour;

  const PriceText({
    super.key,
    required this.price,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.withPerHour = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = NumberFormat('#,###', 'ru_RU')
        .format(int.parse(price))
        .replaceAll(',', ' ');

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: priceText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: fontSize,
              color: color,
              fontWeight: fontWeight,
            ),
          ),
          TextSpan(
            text: ' ₸',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize,
              color: color,
              fontWeight: fontWeight,
              fontFamilyFallback: const ['Noto Sans'],
            ),
          ),
          if (withPerHour)
            TextSpan(
              text: '/час',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                color: color,
                fontWeight: fontWeight,
              ),
            ),
        ],
      ),
    );
  }
}
