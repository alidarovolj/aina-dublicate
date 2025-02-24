import 'package:aina_flutter/core/types/media.dart';

class CommunityCard {
  final int id;
  final String name;
  final Media? avatar;
  final PhoneNumber? whatsapp;
  final String? telegram;
  final String? linkedin;
  final String? email;
  final String? company;
  final String? employment;
  final String? position;
  final Media? image;
  final String? buttonTitle;
  final String? buttonLink;
  final String? textTitle;
  final String? textContent;
  final String? info;
  final PhoneNumber? phone;
  final String? status;

  CommunityCard({
    required this.id,
    required this.name,
    this.avatar,
    this.whatsapp,
    this.telegram,
    this.linkedin,
    this.email,
    this.company,
    this.employment,
    this.position,
    this.image,
    this.buttonTitle,
    this.buttonLink,
    this.textTitle,
    this.textContent,
    this.info,
    this.phone,
    this.status,
  });

  factory CommunityCard.fromJson(Map<String, dynamic> json) {
    return CommunityCard(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'] != null ? Media.fromJson(json['avatar']) : null,
      whatsapp: json['whatsapp'] != null
          ? PhoneNumber.fromJson(json['whatsapp'])
          : null,
      telegram: json['telegram'],
      linkedin: json['linkedin'],
      email: json['email'],
      company: json['company'],
      employment: json['employment'],
      position: json['position'],
      image: json['image'] != null ? Media.fromJson(json['image']) : null,
      buttonTitle: json['button_title'],
      buttonLink: json['button_link'],
      textTitle: json['text_title'],
      textContent: json['text_content'],
      info: json['info'],
      phone: json['phone'] != null ? PhoneNumber.fromJson(json['phone']) : null,
      status: json['status'],
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
