import 'package:aina_flutter/core/types/button_config.dart';

class Promotion {
  final int id;
  final String name;
  final String title;
  final String subtitle;
  final String body;
  final String? bottomBody;
  final PreviewImage previewImage;
  final String? link;
  final String? buildingType;
  final bool isAuthRequired;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final bool isQr;
  final String? minAmountOfReceipt;
  final int? maxCountOfCouponsPerReceipt;
  final int? amountOfCouponsForPromo;
  final int? order;
  final ButtonConfig? button;

  Promotion({
    required this.id,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.body,
    this.bottomBody,
    required this.previewImage,
    this.link,
    this.buildingType,
    required this.isAuthRequired,
    this.startAt,
    this.endAt,
    required this.isActive,
    required this.isQr,
    this.minAmountOfReceipt,
    this.maxCountOfCouponsPerReceipt,
    this.amountOfCouponsForPromo,
    this.order,
    this.button,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as int,
      name: json['name'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      body: json['body'] as String,
      bottomBody: json['bottom_body'] as String?,
      previewImage:
          PreviewImage.fromJson(json['preview_image'] as Map<String, dynamic>),
      link: json['link'] as String?,
      buildingType: json['building_type'] as String?,
      isAuthRequired: json['is_auth_required'] as bool? ?? false,
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : null,
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      isQr: json['is_qr'] as bool? ?? false,
      minAmountOfReceipt: json['min_amount_of_receipt'] as String?,
      maxCountOfCouponsPerReceipt:
          json['max_count_of_coupons_per_receipt'] as int?,
      amountOfCouponsForPromo: json['amount_of_coupons_for_promo'] as int?,
      order: json['order'] as int?,
      button: json['button'] != null
          ? ButtonConfig.fromJson(json['button'] as Map<String, dynamic>)
          : null,
    );
  }

  String get formattedDateRange {
    if (startAt == null || endAt == null) return '';

    return '${_formatDate(startAt!)} - ${_formatDate(endAt!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)}';
  }
}

class PreviewImage {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  PreviewImage({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory PreviewImage.fromJson(Map<String, dynamic> json) {
    return PreviewImage(
      id: json['id'],
      uuid: json['uuid'],
      url: json['url'],
      urlOriginal: json['urlOriginal'],
      orderColumn: json['order_column'],
      collectionName: json['collection_name'],
    );
  }
}
