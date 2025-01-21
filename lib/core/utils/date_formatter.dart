import 'package:intl/intl.dart';

String formatIsoDate(String isoDate,
    {String locale = 'ru', String format = 'yMMMMd'}) {
  try {
    final dateTime = DateTime.parse(isoDate);
    final formatter = DateFormat(format, locale);
    return formatter.format(dateTime);
  } catch (e) {
    print('Error formatting date: $e');
    return isoDate;
  }
}
