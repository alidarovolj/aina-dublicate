class PhoneNumber {
  final String numeric;
  final String masked;

  PhoneNumber({
    required this.numeric,
    required this.masked,
  });

  factory PhoneNumber.fromJson(Map<String, dynamic> json) {
    return PhoneNumber(
      numeric: json['numeric'] as String,
      masked: json['masked'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numeric': numeric,
      'masked': masked,
    };
  }
}

class MediaFile {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  MediaFile({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      url: json['url'] as String,
      urlOriginal: json['urlOriginal'] ?? json['url'] as String,
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

class PromenadeProfile {
  final PhoneNumber? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? patronymic;
  final String? gender;
  final String? iin;
  final MediaFile? avatar;
  final List<dynamic> quotas;
  final bool biometricValid;
  final String? biometricStatus;
  final MediaFile? biometric;

  PromenadeProfile({
    this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.gender,
    this.iin,
    this.avatar,
    this.quotas = const [],
    this.biometricValid = false,
    this.biometricStatus,
    this.biometric,
  });

  /// Checks if the user has completed and validated their biometric verification
  bool get isBiometricVerified =>
      biometricStatus == 'VALID' || (biometricValid && biometric != null);

  /// Checks if the user has submitted biometric data but it's not yet validated
  bool get isBiometricPending =>
      biometricStatus == 'PENDING' || (!biometricValid && biometric != null);

  /// Gets the current biometric verification status
  String getBiometricStatus() {
    if (biometricStatus != null) {
      return biometricStatus!;
    }
    if (isBiometricVerified) {
      return 'VERIFIED';
    } else if (isBiometricPending) {
      return 'PENDING';
    } else {
      return 'NOT_VERIFIED';
    }
  }

  factory PromenadeProfile.fromJson(Map<String, dynamic> json) {
    return PromenadeProfile(
      phone: json['phone'] != null ? PhoneNumber.fromJson(json['phone']) : null,
      email: json['email'] as String?,
      firstName: json['firstname'] as String?,
      lastName: json['lastname'] as String?,
      patronymic: json['patronymic'] as String?,
      gender: json['gender'] as String?,
      iin: json['iin'] as String?,
      avatar:
          json['avatar'] != null ? MediaFile.fromJson(json['avatar']) : null,
      quotas: json['quotas'] as List<dynamic>? ?? [],
      biometricValid: json['biometric_valid'] as bool? ?? false,
      biometricStatus: json['biometric_status'] as String?,
      biometric: json['biometric'] != null
          ? MediaFile.fromJson(json['biometric'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone?.toJson(),
      'email': email,
      'firstname': firstName,
      'lastname': lastName,
      'patronymic': patronymic,
      'gender': gender,
      'iin': iin,
      'avatar': avatar?.toJson(),
      'quotas': quotas,
      'biometric_valid': biometricValid,
      'biometric_status': biometricStatus,
      'biometric': biometric?.toJson(),
    };
  }
}
