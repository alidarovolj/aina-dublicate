import 'package:aina_flutter/core/types/image.dart';
import 'package:aina_flutter/core/types/building.dart';

class Event {
  final String id;
  final String name;
  final String title;
  final String subtitle;
  final String createdAt;
  final String views;
  final ImageData? previewImage;
  final Building? building;

  Event({
    required this.id,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.views,
    this.previewImage,
    this.building,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      subtitle: json['subtitle'],
      createdAt: json['created_at'],
      views: json['views'],
      previewImage: json['preview_image'] != null
          ? ImageData.fromJson(json['preview_image'])
          : null,
      building:
          json['building'] != null ? Building.fromJson(json['building']) : null,
    );
  }
}
