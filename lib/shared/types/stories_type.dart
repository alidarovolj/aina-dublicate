import 'package:aina_flutter/shared/types/button_config.dart';

class Story {
  final int? id; // Changed from String? to int?
  final String? name;
  final String? previewImage;
  final List<StoryItem>? stories;
  final ButtonConfig? button;
  bool read;

  Story({
    this.id,
    this.name,
    this.previewImage,
    this.stories,
    this.button,
    this.read = false,
  });

  Story.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = json['name'] as String?,
        previewImage = json['preview_image']?['url'] as String?,
        button = json['button'] != null
            ? ButtonConfig.fromJson(json['button'] as Map<String, dynamic>)
            : null,
        stories = json['stories'] != null
            ? (() {
                return (json['stories'] as List).map((item) {
                  return StoryItem.fromJson(item as Map<String, dynamic>);
                }).toList();
              })()
            : null,
        read = false;
}

class StoryItem {
  final int? id; // Changed from String? to int?
  final String? name;
  final String? previewImage;
  final int? order; // Changed from String? to int?
  final ButtonConfig? button;

  StoryItem({
    this.id,
    this.name,
    this.previewImage,
    this.order,
    this.button,
  });

  StoryItem.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = json['name'] as String?,
        previewImage = json['preview_image']?['url']
            as String?, // Fixed nested object access
        order = json['order'] as int?,
        button = json['button'] != null
            ? (() {
                return ButtonConfig.fromJson(
                    json['button'] as Map<String, dynamic>);
              })()
            : null;
}
