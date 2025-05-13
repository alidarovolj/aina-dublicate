class ButtonConfig {
  final String? label;
  final String? color;
  final bool? isInternal;
  final String? link;
  final ButtonInternal? internal;

  ButtonConfig({
    this.label,
    this.color,
    this.isInternal,
    this.link,
    this.internal,
  });

  factory ButtonConfig.fromJson(Map<String, dynamic> json) {
    return ButtonConfig(
      label: json['label'] as String?,
      color: json['color'] as String?,
      isInternal: json['is_internal'] as bool?,
      link: json['link'] as String?,
      internal: json['internal'] != null
          ? ButtonInternal.fromJson(json['internal'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ButtonInternal {
  final String model;
  final int? id;
  final String? buildingType;
  final bool isAuthRequired;
  final bool? isQr;
  final int? buildId;

  ButtonInternal({
    required this.model,
    this.id,
    this.buildingType,
    required this.isAuthRequired,
    this.isQr,
    this.buildId,
  });

  factory ButtonInternal.fromJson(Map<String, dynamic> json) {
    return ButtonInternal(
      model: json['model'] as String,
      id: json['id'] as int?,
      buildingType: json['building_type'] as String?,
      isAuthRequired: json['is_auth_required'] as bool? ?? false,
      isQr: json['is_qr'] as bool?,
      buildId: json['building_id'] as int?,
    );
  }
}
