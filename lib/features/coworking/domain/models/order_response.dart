import 'package:aina_flutter/core/types/service.dart';

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
