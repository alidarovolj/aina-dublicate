class Promotion {
  final int id;
  final String name;
  final String title;
  final String subtitle;
  final String body;
  final String bottomBody;
  final PreviewImage previewImage;
  final String? link;
  final String buildingType;
  final bool isAuthRequired;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final bool isQr;
  final String? minAmountOfReceipt;
  final int? maxCountOfCouponsPerReceipt;
  final int? amountOfCouponsForPromo;
  final int order;

  Promotion({
    required this.id,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bottomBody,
    required this.previewImage,
    this.link,
    required this.buildingType,
    required this.isAuthRequired,
    this.startAt,
    this.endAt,
    required this.isActive,
    required this.isQr,
    this.minAmountOfReceipt,
    this.maxCountOfCouponsPerReceipt,
    this.amountOfCouponsForPromo,
    required this.order,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      subtitle: json['subtitle'],
      body: json['body'],
      bottomBody: json['bottom_body'],
      previewImage: PreviewImage.fromJson(json['preview_image']),
      link: json['link'],
      buildingType: json['building_type'] ?? '',
      isAuthRequired: json['is_auth_required'] ?? false,
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at']).toLocal()
          : null,
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at']).toLocal()
          : null,
      isActive: json['is_active'] ?? false,
      isQr: json['is_qr'] ?? false,
      minAmountOfReceipt: json['min_amount_of_receipt']?.toString(),
      maxCountOfCouponsPerReceipt: json['max_count_of_coupons_per_receipt'],
      amountOfCouponsForPromo: json['amount_of_coupons_for_promo'],
      order: json['order'] ?? 0,
    );
  }

  String get formattedDateRange {
    if (startAt == null || endAt == null) return '';

    // Add debug print to check the dates
    print('Start date: $startAt');
    print('End date: $endAt');

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
