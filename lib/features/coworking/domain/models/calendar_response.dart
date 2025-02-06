class CalendarResponse {
  final List<TimeRange> data;

  CalendarResponse({required this.data});

  factory CalendarResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataJson = json['data'] ?? [];
    return CalendarResponse(
      data: dataJson.map((item) => TimeRange.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data.map((item) => item.toJson()).toList(),
      };
}

class TimeRange {
  final String startAt;
  final String endAt;

  TimeRange({required this.startAt, required this.endAt});

  factory TimeRange.fromJson(Map<String, dynamic> json) => TimeRange(
        startAt: json['start_at'] as String,
        endAt: json['end_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'start_at': startAt,
        'end_at': endAt,
      };
}
