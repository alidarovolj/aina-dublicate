class StoreCategory {
  final int id;
  final String title;
  final int order;
  final CategoryImage? image;

  StoreCategory({
    required this.id,
    required this.title,
    required this.order,
    this.image,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    return StoreCategory(
      id: json['id'] as int,
      title: json['title'] as String,
      order: json['order'] as int? ?? 0,
      image: json['preview_image'] != null
          ? CategoryImage.fromJson(json['preview_image'])
          : null,
    );
  }
}

class CategoryImage {
  final String url;
  final String urlOriginal;

  CategoryImage({
    required this.url,
    required this.urlOriginal,
  });

  factory CategoryImage.fromJson(Map<String, dynamic> json) {
    return CategoryImage(
      url: json['url'] as String,
      urlOriginal: json['urlOriginal'] as String,
    );
  }
}
