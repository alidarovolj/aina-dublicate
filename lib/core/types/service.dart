class Service {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String? subtype;
  final int? parentId;
  final int sort;
  final String? createdAt;
  final String? updatedAt;
  final ServiceImage? image;
  final List<ServiceImage>? gallery;
  final int? price;
  final int? categoryId;
  final Service? category;

  Service({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.subtype,
    this.parentId,
    required this.sort,
    this.createdAt,
    this.updatedAt,
    this.image,
    this.gallery,
    this.price,
    this.categoryId,
    this.category,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      subtype: json['subtype'] as String?,
      parentId: json['parent_id'] as int?,
      sort: json['sort'] as int,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      image: json['image'] != null
          ? ServiceImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      gallery: (json['gallery'] as List<dynamic>?)
          ?.map((e) => ServiceImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: json['price'] as int?,
      categoryId: json['category_id'] as int?,
      category: json['category'] != null
          ? Service.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'subtype': subtype,
      'parent_id': parentId,
      'sort': sort,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image': image?.toJson(),
      'gallery': gallery?.map((e) => e.toJson()).toList(),
      'price': price,
      'category_id': categoryId,
      'category': category?.toJson(),
    };
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
      urlOriginal: json['urlOriginal'] as String,
      orderColumn: json['order_column'] as int,
      collectionName: json['collection_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'url': url,
      'urlOriginal': urlOriginal,
      'order_column': orderColumn,
      'collection_name': collectionName,
    };
  }
}
