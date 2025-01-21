class Category {
  final int id;
  final String title;
  final String description;
  final int order;
  final CategoryImage? image;

  Category({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
      image:
          json['image'] != null ? CategoryImage.fromJson(json['image']) : null,
    );
  }
}

class CategoryImage {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  CategoryImage({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory CategoryImage.fromJson(Map<String, dynamic> json) {
    return CategoryImage(
      id: json['id'],
      uuid: json['uuid'],
      url: json['url'],
      urlOriginal: json['urlOriginal'],
      orderColumn: json['order_column'],
      collectionName: json['collection_name'],
    );
  }
}
