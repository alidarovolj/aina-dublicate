class OrderRequest {
  final String startAt;
  final String endAt;
  final int serviceId;

  OrderRequest({
    required this.startAt,
    required this.endAt,
    required this.serviceId,
  });

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    return OrderRequest(
      startAt: json['start_at'] as String,
      endAt: json['end_at'] as String,
      serviceId: json['service_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_at': startAt,
      'end_at': endAt,
      'service_id': serviceId,
    };
  }
}
