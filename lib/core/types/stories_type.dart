class Story {
  final int? id; // Changed from String? to int?
  final String? name;
  final String? previewImage;
  final List<StoryItem>? stories;
  bool read;

  Story({
    this.id,
    this.name,
    this.previewImage,
    this.stories,
    this.read = false,
  });

  Story.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?, // Cast to int?
        name = json['name'] as String?,
        previewImage = json['preview_image']?['url']
            as String?, // Fixed nested object access
        stories = json['stories'] != null
            ? (json['stories'] as List)
                .map((item) => StoryItem.fromJson(item as Map<String, dynamic>))
                .toList()
            : null,
        read = false;
}

class StoryItem {
  final int? id; // Changed from String? to int?
  final String? name;
  final String? previewImage;
  final int? order; // Changed from String? to int?

  StoryItem({
    this.id,
    this.name,
    this.previewImage,
    this.order,
  });

  StoryItem.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = json['name'] as String?,
        previewImage = json['preview_image']?['url']
            as String?, // Fixed nested object access
        order = json['order'] as int?;
}
