import 'package:flutter/material.dart';
import 'package:aina_flutter/core/types/button_config.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

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
    // print('Parsing PreviewImage: $json');
    return PreviewImage(
      id: json['id'],
      uuid: json['uuid'],
      url: json['url'],
      urlOriginal: json['urlOriginal'] ?? json['blob'],
      orderColumn: json['order_column'] ?? 1,
      collectionName: json['collection_name'],
    );
  }
}

class Building {
  final int id;
  final String type;
  final String name;
  final String phone;
  final String latitude;
  final String longitude;
  final String description;
  final PreviewImage previewImage;
  final List<PreviewImage> images;
  final String workingHours;
  final String address;
  final DateTime createdAt;

  Building({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.previewImage,
    required this.images,
    required this.workingHours,
    required this.address,
    required this.createdAt,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    List<PreviewImage> images = [];
    if (json['images'] != null) {
      final imagesList = json['images'] as List;
      for (var imageJson in imagesList) {
        images.add(PreviewImage.fromJson(imageJson as Map<String, dynamic>));
      }
    }

    return Building(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      description: json['description'] as String,
      previewImage:
          PreviewImage.fromJson(json['preview_image'] as Map<String, dynamic>),
      images: images,
      workingHours: json['working_hours'] as String,
      address: json['address'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Promotion {
  final int id;
  final String name;
  final String title;
  final String subtitle;
  final String body;
  final String? bottomBody;
  final PreviewImage previewImage;
  final List<PreviewImage> images;
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
  final Building? building;
  final String? type;
  final PreviewImage? file;

  Promotion({
    required this.id,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.body,
    this.bottomBody,
    required this.previewImage,
    required this.images,
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
    this.building,
    this.type,
    this.file,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing promotion JSON: $json');

      // Обработка preview_image
      PreviewImage? previewImage;
      if (json['preview_image'] != null) {
        previewImage = PreviewImage.fromJson(
            json['preview_image'] as Map<String, dynamic>);
      } else if (json['media'] != null && (json['media'] as List).isNotEmpty) {
        previewImage = PreviewImage.fromJson(
            (json['media'] as List).first as Map<String, dynamic>);
      }

      // Обработка images
      List<PreviewImage> images = [];
      if (json['images'] != null) {
        final imagesList = json['images'] as List;
        for (var imageJson in imagesList) {
          try {
            images
                .add(PreviewImage.fromJson(imageJson as Map<String, dynamic>));
          } catch (e) {
            // print('Error parsing image: $e');
          }
        }
      }

      // Обработка дат
      DateTime? startAt;
      try {
        startAt = json['start_at'] != null
            ? DateTime.parse(json['start_at'] as String)
            : null;
      } catch (e) {
        // print('Error parsing start_at: $e');
      }

      DateTime? endAt;
      try {
        endAt = json['end_at'] != null
            ? DateTime.parse(json['end_at'] as String)
            : null;
      } catch (e) {
        // print('Error parsing end_at: $e');
      }

      Building? building;
      if (json['building'] != null) {
        building = Building.fromJson(json['building'] as Map<String, dynamic>);
      }

      PreviewImage? file;
      if (json['file'] != null) {
        file = PreviewImage.fromJson(json['file'] as Map<String, dynamic>);
      }

      return Promotion(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        body: json['body'] as String? ?? '',
        bottomBody: json['bottom_body'] as String?,
        previewImage: previewImage ??
            PreviewImage(
              id: 0,
              uuid: '',
              url: '',
              urlOriginal: '',
              orderColumn: 1,
              collectionName: '',
            ),
        images: images,
        isAuthRequired: json['is_auth_required'] as bool? ?? false,
        startAt: startAt,
        endAt: endAt,
        isActive: json['is_active'] as bool? ?? true,
        isQr: json['is_qr'] as bool? ?? false,
        minAmountOfReceipt: json['min_amount_of_receipt']?.toString(),
        maxCountOfCouponsPerReceipt:
            json['max_count_of_coupons_per_receipt'] as int?,
        amountOfCouponsForPromo: json['amount_of_coupons_for_promo'] as int?,
        order: json['order'] as int?,
        button: json['button'] != null
            ? ButtonConfig.fromJson(json['button'] as Map<String, dynamic>)
            : null,
        building: building,
        type: json['type'] as String?,
        file: file,
      );
    } catch (e) {
      // print('Error parsing promotion: $e');
      // print('Stack trace: $stack');
      rethrow;
    }
  }

  String get formattedDateRange {
    if (startAt == null && endAt == null) {
      return 'promotions.unlimited'.tr();
    }

    final dateFormat = DateFormat('dd.MM.yyyy');
    final startStr = startAt != null ? dateFormat.format(startAt!) : '';
    final endStr = endAt != null ? dateFormat.format(endAt!) : '';

    if (startAt != null && endAt != null) {
      return '$startStr - $endStr';
    } else if (startAt != null) {
      return 'promotions.from_date'.tr(args: [startStr]);
    } else {
      return 'promotions.until_date'.tr(args: [endStr]);
    }
  }
}
