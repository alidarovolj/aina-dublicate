import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service_image.dart';

class CoworkingTariffDetails {
  final int id;
  final String type;
  final int categoryId;
  final String title;
  final String subtitle;
  final int price;
  final String timeUnit;
  final int? duration;
  final String? startDay;
  final String? startTimeAt;
  final String? endTimeAt;
  final bool useFreeQuota;
  final Map<String, String> freeQuotas;
  final int sort;
  final String description;
  final CoworkingServiceImage? image;
  final List<CoworkingServiceImage> gallery;
  final List<ReservedDateRange> reservedDates;
  final double? timeStep;
  final int? minDuration;

  CoworkingTariffDetails({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.timeUnit,
    required this.duration,
    this.startDay,
    this.startTimeAt,
    this.endTimeAt,
    required this.useFreeQuota,
    required this.freeQuotas,
    required this.sort,
    required this.description,
    this.image,
    required this.gallery,
    this.reservedDates = const [],
    this.timeStep,
    this.minDuration,
  });

  factory CoworkingTariffDetails.fromJson(Map<String, dynamic> json) {
    return CoworkingTariffDetails(
      id: json['id'] as int,
      type: json['type'] as String,
      categoryId: json['category_id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      price: json['price'] as int,
      timeUnit: json['time_unit'] as String,
      duration: json['duration'] as int?,
      startDay: json['start_day'] as String?,
      startTimeAt: json['start_time_at'] as String?,
      endTimeAt: json['end_time_at'] as String?,
      useFreeQuota: json['use_free_quota'] as bool? ?? false,
      freeQuotas: json['free_quotas'] != null
          ? Map<String, String>.from(json['free_quotas'] as Map)
          : {},
      sort: json['sort'] as int,
      description: json['description'] as String,
      image: json['image'] != null
          ? CoworkingServiceImage.fromJson(
              json['image'] as Map<String, dynamic>)
          : null,
      gallery: (json['gallery'] as List<dynamic>)
          .map((e) => CoworkingServiceImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      reservedDates: json['reserved_dates'] != null
          ? (json['reserved_dates'] as List<dynamic>)
              .map((e) => ReservedDateRange.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      timeStep: (json['time_step'] as num?)?.toDouble(),
      minDuration: json['min_duration'] as int?,
    );
  }
}

class ReservedDateRange {
  final String startAt;
  final String endAt;

  ReservedDateRange({
    required this.startAt,
    required this.endAt,
  });

  factory ReservedDateRange.fromJson(Map<String, dynamic> json) {
    return ReservedDateRange(
      startAt: json['start_at'] as String,
      endAt: json['end_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_at': startAt,
      'end_at': endAt,
    };
  }
}
