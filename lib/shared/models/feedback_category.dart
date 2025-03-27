class FeedbackCategory {
  final int id;
  final String title;
  final String description;
  final String type;
  final int? parentId;
  final List<FeedbackCategory> children;
  final int sort;
  final String createdAt;
  final String updatedAt;
  final String? image;
  final List<String> gallery;

  FeedbackCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.parentId,
    this.children = const [],
    required this.sort,
    required this.createdAt,
    required this.updatedAt,
    this.image,
    this.gallery = const [],
  });

  factory FeedbackCategory.fromJson(Map<String, dynamic> json) {
    return FeedbackCategory(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      parentId: json['parent_id'] as int?,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => FeedbackCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sort: json['sort'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      image: json['image'] as String?,
      gallery: (json['gallery'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
