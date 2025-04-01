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
