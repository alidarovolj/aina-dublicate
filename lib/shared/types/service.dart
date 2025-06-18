import 'package:aina_flutter/shared/models/service_image.dart';

class Service {
  final int? id;
  final String title;
  final String? description;
  final String type;
  final String? subtype;
  final int? parentId;
  final int? sort;
  final String? createdAt;
  final String? updatedAt;
  final ServiceImage? image;
  final List<ServiceImage>? gallery;
  final int? price;
  final int? categoryId;
  final Service? category;
  final String? subtitle;
  final String? unit;
  final bool? isFixed;
  final bool? isActive;
  final int? capacity;

  Service({
    this.id,
    required this.title,
    this.description,
    required this.type,
    this.subtype,
    this.parentId,
    this.sort,
    this.createdAt,
    this.updatedAt,
    this.image,
    this.gallery,
    this.price,
    this.categoryId,
    this.category,
    this.subtitle,
    this.unit,
    this.isFixed,
    this.isActive,
    this.capacity,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      subtype: json['subtype'] as String?,
      parentId: json['parent_id'] as int?,
      sort: json['sort'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      image: json['image'] != null
          ? ServiceImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      gallery: (json['gallery'] as List<dynamic>?)
          ?.map((e) => ServiceImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: json['price'] as int?,
      categoryId: json['category_id'] as int?,
      category: json['category'] != null
          ? Service.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      subtitle: json['subtitle'] as String?,
      unit: json['unit'] as String?,
      isFixed: json['is_fixed'] as bool?,
      isActive: json['is_active'] as bool?,
      capacity: json['capacity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'subtype': subtype,
      'parent_id': parentId,
      'sort': sort,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image': image?.toJson(),
      'gallery': gallery?.map((e) => e.toJson()).toList(),
      'price': price,
      'category_id': categoryId,
      'category': category?.toJson(),
      'subtitle': subtitle,
      'unit': unit,
      'is_fixed': isFixed,
      'is_active': isActive,
      'capacity': capacity,
    };
  }
}
