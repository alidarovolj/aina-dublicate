class ConferenceService {
  final int id;
  final String title;
  final String description;
  final String type;
  final ServiceImage? image;
  final List<ServiceImage> gallery;

  ConferenceService({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.image,
    required this.gallery,
  });

  factory ConferenceService.fromJson(Map<String, dynamic> json) {
    return ConferenceService(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      image:
          json['image'] != null ? ServiceImage.fromJson(json['image']) : null,
      gallery: (json['gallery'] as List<dynamic>)
          .map((e) => ServiceImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConferenceTariff {
  final int id;
  final String type;
  final bool isActive;
  final int categoryId;
  final String title;
  final String subtitle;
  final int price;
  final String timeUnit;
  final bool isFixed;
  final ServiceImage? image;
  final String description;
  final int capacity;

  ConferenceTariff({
    required this.id,
    required this.type,
    required this.isActive,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.timeUnit,
    required this.isFixed,
    this.image,
    required this.description,
    required this.capacity,
  });

  factory ConferenceTariff.fromJson(Map<String, dynamic> json) {
    return ConferenceTariff(
      id: json['id'] as int,
      type: json['type'] as String,
      isActive: json['is_active'] as bool,
      categoryId: json['category_id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      price: json['price'] as int,
      timeUnit: json['time_unit'] as String,
      isFixed: json['is_fixed'] as bool,
      image:
          json['image'] != null ? ServiceImage.fromJson(json['image']) : null,
      description: json['description'] as String,
      capacity: json['capacity'] as int,
    );
  }
}

class ServiceImage {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  ServiceImage({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      url: json['url'] as String,
      urlOriginal: json['url_original'] as String,
      orderColumn: json['order_column'] as int,
      collectionName: json['collection_name'] as String,
    );
  }
}
