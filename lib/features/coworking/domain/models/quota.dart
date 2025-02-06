class Quota {
  final int id;
  final int orderId;
  final String type;
  final int amount;
  final int initialAmount;
  final String startAt;
  final String endAt;
  final String createdAt;

  const Quota({
    required this.id,
    required this.orderId,
    required this.type,
    required this.amount,
    required this.initialAmount,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
  });

  factory Quota.fromJson(Map<String, dynamic> json) {
    return Quota(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      type: json['type'] as String,
      amount: json['amount'] as int,
      initialAmount: json['initial_amount'] as int,
      startAt: json['start_at'] as String,
      endAt: json['end_at'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'type': type,
      'amount': amount,
      'initial_amount': initialAmount,
      'start_at': startAt,
      'end_at': endAt,
      'created_at': createdAt,
    };
  }
}

class Service {
  final int id;
  final String type;
  final String title;
  final ServiceImage? image;

  const Service({
    required this.id,
    required this.type,
    required this.title,
    this.image,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      image:
          json['image'] != null ? ServiceImage.fromJson(json['image']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'image': image?.toJson(),
    };
  }
}

class ServiceImage {
  final String url;

  const ServiceImage({
    required this.url,
  });

  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}
