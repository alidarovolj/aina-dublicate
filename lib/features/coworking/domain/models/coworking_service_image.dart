class CoworkingServiceImage {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  CoworkingServiceImage({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory CoworkingServiceImage.fromJson(Map<String, dynamic> json) {
    return CoworkingServiceImage(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      url: json['url'] as String,
      urlOriginal: json['urlOriginal'] as String,
      orderColumn: json['order_column'] as int,
      collectionName: json['collection_name'] as String,
    );
  }
}
