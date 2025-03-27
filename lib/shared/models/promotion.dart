class Promotion {
  // ... other properties
  final Map<String, dynamic>? button;

  Promotion({
    // ... other parameters
    this.button,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      // ... other fields
      button: json['button'] as Map<String, dynamic>?,
    );
  }
}
