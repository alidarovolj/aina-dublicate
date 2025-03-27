import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;

String formatIsoDate(String isoDate,
    {String locale = 'ru', String format = 'yMMMMd'}) {
  try {
    final dateTime = DateTime.parse(isoDate);
    final formatter = DateFormat(format, locale);
    return formatter.format(dateTime);
  } catch (e) {
    debugPrint('Error formatting date: $e');
    return isoDate;
  }
}
