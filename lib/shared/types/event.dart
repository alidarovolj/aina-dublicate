import 'package:aina_flutter/shared/types/button.dart';
import 'package:aina_flutter/shared/types/building.dart';
import 'package:intl/intl.dart';

class Event {
  final int id;
  final String title;
  final String subtitle;
  final String body;
  final String? bottomBody;
  final PreviewImage previewImage;
  final DateTime startAt;
  final DateTime endAt;
  final Building? building;
  final Button? button;

  Event({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    this.bottomBody,
    required this.previewImage,
    required this.startAt,
    required this.endAt,
    this.building,
    this.button,
  });

  String get formattedDateRange {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final startDate = dateFormat.format(startAt);
    final endDate = dateFormat.format(endAt);
    return '$startDate - $endDate';
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'] ?? '',
      body: json['body'] ?? '',
      bottomBody: json['bottom_body'],
      previewImage: PreviewImage.fromJson(json['preview_image']),
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      building:
          json['building'] != null ? Building.fromJson(json['building']) : null,
      button: json['button'] != null ? Button.fromJson(json['button']) : null,
    );
  }
}
