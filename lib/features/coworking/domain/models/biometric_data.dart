import 'package:aina_flutter/core/types/media.dart';

class BiometricData {
  final int id;
  final PhoneNumber phone;
  final String? firstname;
  final String? lastname;
  final String? biometricStatus;
  final Media? biometric;

  BiometricData({
    required this.id,
    required this.phone,
    this.firstname,
    this.lastname,
    this.biometricStatus,
    this.biometric,
  });

  factory BiometricData.fromJson(Map<String, dynamic> json) {
    return BiometricData(
      id: json['id'],
      phone: PhoneNumber.fromJson(json['phone']),
      firstname: json['firstname'],
      lastname: json['lastname'],
      biometricStatus: json['biometric_status'],
      biometric:
          json['biometric'] != null ? Media.fromJson(json['biometric']) : null,
    );
  }
}

class PhoneNumber {
  final String numeric;
  final String masked;

  PhoneNumber({
    required this.numeric,
    required this.masked,
  });

  factory PhoneNumber.fromJson(Map<String, dynamic> json) {
    return PhoneNumber(
      numeric: json['numeric'],
      masked: json['masked'],
    );
  }
}
