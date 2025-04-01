import 'package:aina_flutter/shared/models/service_image.dart';

class Quota {
  final int id;
  final int userId;
  final int coworkingId;
  final String name;
  final String tariffName;
  final String tariffType;
  final String beginAt;
  final String endAt;
  final String createdAt;
  final ServiceImage? image;

  const Quota({
    required this.id,
    required this.userId,
    required this.coworkingId,
    required this.name,
    required this.tariffName,
    required this.tariffType,
    required this.beginAt,
    required this.endAt,
    required this.createdAt,
    this.image,
  });

  factory Quota.fromJson(Map<String, dynamic> json) {
    return Quota(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      coworkingId: json['coworking_id'] as int,
      name: json['name'] as String,
      tariffName: json['tariff_name'] as String,
      tariffType: json['tariff_type'] as String,
      beginAt: json['begin_at'] as String,
      endAt: json['end_at'] as String,
      createdAt: json['created_at'] as String,
      image: json['image'] != null
          ? ServiceImage(
              id: 0, // Используем 0 в качестве значения по умолчанию для id
              url: json['image']['url'] as String,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coworking_id': coworkingId,
      'name': name,
      'tariff_name': tariffName,
      'tariff_type': tariffType,
      'begin_at': beginAt,
      'end_at': endAt,
      'created_at': createdAt,
      'image': image?.toJson(),
    };
  }
}

class Service {
  final int id;
  final String type;
  final String title;
  final ServiceImage? image;

  const Service({
    required this.id,
    required this.type,
    required this.title,
    this.image,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      image:
          json['image'] != null ? ServiceImage.fromJson(json['image']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'image': image?.toJson(),
    };
  }
}
