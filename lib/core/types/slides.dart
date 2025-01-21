class Slide {
  final int id;
  final String name;
  final PreviewImage previewImage;
  final bool? isAuthorized;
  final int order;
  final Button? button;

  const Slide({
    required this.id,
    required this.name,
    required this.previewImage,
    this.isAuthorized,
    required this.order,
    this.button,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as int,
      name: json['name'] as String,
      previewImage: PreviewImage.fromJson(json['preview_image']),
      isAuthorized: json['is_authorized'],
      order: json['order'] as int,
      button: json['button'] != null ? Button.fromJson(json['button']) : null,
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
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      url: json['url'] as String,
      urlOriginal: json['urlOriginal'] as String,
      orderColumn: json['order_column'] as int,
      collectionName: json['collection_name'] as String,
    );
  }
}

class Button {
  final String label;
  final String? color;
  final bool isInternal;
  final String link;
  final ButtonInternal? internal;

  Button({
    required this.label,
    this.color,
    required this.isInternal,
    required this.link,
    this.internal,
  });

  factory Button.fromJson(Map<String, dynamic> json) {
    return Button(
      label: json['label'] as String,
      color: json['color'],
      isInternal: json['is_internal'] as bool,
      link: json['link'] as String,
      internal: json['internal'] != null
          ? ButtonInternal.fromJson(json['internal'])
          : null,
    );
  }
}

class ButtonInternal {
  final String model;
  final int id;
  final String buildingType;
  final bool isAuthRequired;

  ButtonInternal({
    required this.model,
    required this.id,
    required this.buildingType,
    required this.isAuthRequired,
  });

  factory ButtonInternal.fromJson(Map<String, dynamic> json) {
    return ButtonInternal(
      model: json['model'] as String,
      id: json['id'] as int,
      buildingType: json['building_type'] as String,
      isAuthRequired: json['is_auth_required'] as bool,
    );
  }
}
