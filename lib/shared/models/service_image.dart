class ServiceImage {
  final int id;
  final String url;
  final String? urlOriginal;
  final String? collectionName;
  final int? orderColumn;

  ServiceImage({
    required this.id,
    required this.url,
    this.urlOriginal,
    this.collectionName,
    this.orderColumn,
  });

  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      id: json['id'] as int,
      url: json['url'] as String,
      urlOriginal: json['url_original'] as String? ?? json['url'] as String,
      collectionName: json['collection_name'] as String?,
      orderColumn: json['order_column'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'url_original': urlOriginal,
      'collection_name': collectionName,
      'order_column': orderColumn,
    };
  }
}
