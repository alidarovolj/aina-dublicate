class Store {
  final int id;
  final String name;
  final String? shortDescription;
  final StoreImage? previewImage;

  Store({
    required this.id,
    required this.name,
    this.shortDescription,
    this.previewImage,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      name: json['name'] as String,
      shortDescription: json['short_description'] as String?,
      previewImage: json['preview_image'] != null
          ? StoreImage.fromJson(json['preview_image'])
          : null,
    );
  }
}

class StoreImage {
  final String url;
  final String urlOriginal;

  StoreImage({
    required this.url,
    required this.urlOriginal,
  });

  factory StoreImage.fromJson(Map<String, dynamic> json) {
    return StoreImage(
      url: json['url'] as String,
      urlOriginal: json['urlOriginal'] as String,
    );
  }
}
