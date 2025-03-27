import 'package:aina_flutter/shared/types/button.dart';
import 'package:aina_flutter/shared/types/building.dart';
import 'package:intl/intl.dart';

class NewsResponse {
  final List<News> data;
  final NewsPagination? pagination;
  final List<String> filters;

  NewsResponse({
    required this.data,
    this.pagination,
    this.filters = const [],
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final List<News> newsList;

    if (data is List) {
      newsList = data.map((item) => News.fromJson(item)).toList();
    } else if (data is Map<String, dynamic>) {
      newsList = [News.fromJson(data)];
    } else {
      newsList = [];
    }

    return NewsResponse(
      data: newsList,
      pagination: json['pagination'] != null
          ? NewsPagination.fromJson(json['pagination'])
          : null,
      filters:
          (json['filters'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class NewsPagination {
  final int currentPage;
  final int from;
  final bool hasNextPage;
  final int lastPage;
  final int perPage;
  final int to;
  final int total;

  NewsPagination({
    required this.currentPage,
    required this.from,
    required this.hasNextPage,
    required this.lastPage,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory NewsPagination.fromJson(Map<String, dynamic> json) {
    return NewsPagination(
      currentPage: json['current_page'],
      from: json['from'],
      hasNextPage: json['has_next_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      to: json['to'],
      total: json['total'],
    );
  }
}

class News {
  final int id;
  final String name;
  final String title;
  final String subtitle;
  final String body;
  final String? bottomBody;
  final String createdAt;
  final int views;
  final PreviewImage previewImage;
  final List<PreviewImage> images;
  final Button? button;
  final Building? building;

  News({
    required this.id,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.body,
    this.bottomBody,
    required this.createdAt,
    required this.views,
    required this.previewImage,
    required this.images,
    this.button,
    this.building,
  });

  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return createdAt;
    }
  }

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      subtitle: json['subtitle'],
      body: json['body'] ?? '',
      bottomBody: json['bottom_body'],
      createdAt: json['created_at'],
      views: json['views'],
      previewImage: PreviewImage.fromJson(json['preview_image']),
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => PreviewImage.fromJson(image))
              .toList() ??
          [],
      button: json['button'] != null ? Button.fromJson(json['button']) : null,
      building:
          json['building'] != null ? Building.fromJson(json['building']) : null,
    );
  }
}
