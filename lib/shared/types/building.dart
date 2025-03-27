class Building {
  final int id;
  final String name;
  final String type;
  final String phone;
  final String latitude;
  final String longitude;
  final String description;
  final String workingHours;
  final String address;
  final String createdAt;
  final PreviewImage previewImage;
  final List<BuildingImage> images;

  Building({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.workingHours,
    required this.address,
    required this.createdAt,
    required this.previewImage,
    required this.images,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      phone: json['phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
      workingHours: json['working_hours'],
      address: json['address'],
      createdAt: json['created_at'],
      previewImage: PreviewImage.fromJson(json['preview_image']),
      images: (json['images'] as List)
          .map((image) => BuildingImage.fromJson(image))
          .toList(),
    );
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

class BuildingImage {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  BuildingImage({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory BuildingImage.fromJson(Map<String, dynamic> json) {
    return BuildingImage(
      id: json['id'],
      uuid: json['uuid'],
      url: json['url'],
      urlOriginal: json['urlOriginal'],
      orderColumn: json['order_column'],
      collectionName: json['collection_name'],
    );
  }
}
