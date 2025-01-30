class ButtonInternal {
  final String model;
  final int? id;
  final String? buildingType;
  final bool isAuthRequired;

  ButtonInternal({
    required this.model,
    this.id,
    this.buildingType,
    required this.isAuthRequired,
  });

  factory ButtonInternal.fromJson(Map<String, dynamic> json) {
    return ButtonInternal(
      model: json['model'] ?? '',
      id: json['id'],
      buildingType: json['building_type'],
      isAuthRequired: json['is_auth_required'] ?? false,
    );
  }
}

class Button {
  final String label;
  final String? color;
  final bool isInternal;
  final String? link;
  final ButtonInternal? internal;

  Button({
    required this.label,
    this.color,
    required this.isInternal,
    this.link,
    this.internal,
  });

  factory Button.fromJson(Map<String, dynamic> json) {
    return Button(
      label: json['label'] ?? '',
      color: json['color'],
      isInternal: json['is_internal'] ?? false,
      link: json['link'],
      internal: json['internal'] != null
          ? ButtonInternal.fromJson(json['internal'])
          : null,
    );
  }
}
