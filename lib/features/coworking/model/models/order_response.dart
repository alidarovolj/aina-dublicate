import 'package:aina_flutter/shared/types/service.dart';
// Assuming ImageMedia exists and is suitable

// Define PreviewImage if ImageMedia is not suitable or doesn't exist
class PreviewImage {
  final int id;
  final String uuid;
  final String? name;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  PreviewImage({
    required this.id,
    required this.uuid,
    this.name,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory PreviewImage.fromJson(Map<String, dynamic> json) {
    return PreviewImage(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      name: json['name'] as String?,
      url: json['url'] as String,
      urlOriginal: json['urlOriginal'] as String,
      orderColumn: json['order_column'] as int,
      collectionName: json['collection_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'url': url,
      'urlOriginal': urlOriginal,
      'order_column': orderColumn,
      'collection_name': collectionName,
    };
  }
}

class Company {
  final int id;
  final String name;
  final String? legalName;
  final PreviewImage? previewImage; // Use the defined PreviewImage model

  Company({
    required this.id,
    required this.name,
    this.legalName,
    this.previewImage,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      legalName: json['legal_name'] as String?,
      previewImage: json['preview_image'] != null
          ? PreviewImage.fromJson(json['preview_image'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'legal_name': legalName,
      'preview_image': previewImage?.toJson(),
    };
  }
}

class OrderResponse {
  final int id;
  final String status;
  final int total;
  final double duration;
  final String startAt;
  final String endAt;
  final String createdAt;
  final int serviceId;
  final String? fiscalLinkUrl;
  final PaymentMethod? paymentMethod;
  final Service? service;
  final List<OrderHistory>? history;
  final double appliedQuotaHours;
  final double appliedDiscountPercentage;
  final Company? company; // Add company field

  OrderResponse({
    required this.id,
    required this.status,
    required this.total,
    required this.duration,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.serviceId,
    this.fiscalLinkUrl,
    this.paymentMethod,
    this.service,
    this.history,
    this.appliedQuotaHours = 0,
    this.appliedDiscountPercentage = 0,
    this.company, // Add to constructor
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as int,
      status: json['status'] as String,
      total: json['total'] as int,
      duration: (json['duration_numeric'] as num?)?.toDouble() ?? 0.0,
      startAt: json['start_at'] as String,
      endAt: json['end_at'] as String,
      createdAt: json['created_at'] as String,
      serviceId: json['service_id'] as int,
      fiscalLinkUrl: json['fiscal_link_url'] as String?,
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.fromJson(
              json['payment_method'] as Map<String, dynamic>)
          : null,
      service: json['service'] != null
          ? Service.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => OrderHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      appliedQuotaHours: (json['applied_quota_hours'] as num?)?.toDouble() ?? 0,
      appliedDiscountPercentage:
          (json['applied_discount_percentage'] as num?)?.toDouble() ?? 0,
      company: json['company'] != null // Parse company object
          ? Company.fromJson(json['company'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'total': total,
      'duration_numeric': duration,
      'start_at': startAt,
      'end_at': endAt,
      'created_at': createdAt,
      'service_id': serviceId,
      'fiscal_link_url': fiscalLinkUrl,
      'payment_method': paymentMethod?.toJson(),
      'service': service?.toJson(),
      'history': history?.map((e) => e.toJson()).toList(),
      'applied_quota_hours': appliedQuotaHours,
      'applied_discount_percentage': appliedDiscountPercentage,
      'company': company?.toJson(), // Add to toJson
    };
  }
}

class PaymentMethod {
  final int id;
  final String type;
  final String? name;

  PaymentMethod({
    required this.id,
    required this.type,
    this.name,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
    };
  }
}

class OrderHistory {
  final String message;
  final String actionAt;

  OrderHistory({
    required this.message,
    required this.actionAt,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      message: json['message'] as String,
      actionAt: json['action_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'action_at': actionAt,
    };
  }
}
