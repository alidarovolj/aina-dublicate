class ImageData {
  final String url;
  final String? alt;
  final int? width;
  final int? height;

  ImageData({
    required this.url,
    this.alt,
    this.width,
    this.height,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      url: json['url'],
      alt: json['alt'],
      width: json['width'],
      height: json['height'],
    );
  }
}
