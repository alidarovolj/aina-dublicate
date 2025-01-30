class Service {
  final int id;
  final String title;
  final String description;
  final String type;
  final int? parentId;
  final int sort;
  final String createdAt;
  final String updatedAt;
  final ServiceImage? image;
  final List<ServiceImage>? gallery;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.parentId,
    required this.sort,
    required this.createdAt,
    required this.updatedAt,
    this.image,
    this.gallery,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      parentId: json['parent_id'],
      sort: json['sort'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      image:
          json['image'] != null ? ServiceImage.fromJson(json['image']) : null,
      gallery: json['gallery'] != null
          ? List<ServiceImage>.from(
              json['gallery'].map((x) => ServiceImage.fromJson(x)))
          : null,
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
      id: json['id'],
      uuid: json['uuid'],
      url: json['url'],
      urlOriginal: json['urlOriginal'],
      orderColumn: json['order_column'],
      collectionName: json['collection_name'],
    );
  }
}
