class PreCalculationResponse {
  final int subtotal;
  final int? appliedQuotaHours;
  final int appliedDiscountPercentage;
  final int bonusAmount;
  final int total;
  final String durationHumanized;

  PreCalculationResponse({
    required this.subtotal,
    this.appliedQuotaHours,
    required this.appliedDiscountPercentage,
    required this.bonusAmount,
    required this.total,
    required this.durationHumanized,
  });

  factory PreCalculationResponse.fromJson(Map<String, dynamic> json) {
    return PreCalculationResponse(
      subtotal: json['subtotal'] as int,
      appliedQuotaHours: json['applied_quota_hours'] as int?,
      appliedDiscountPercentage: json['applied_discount_percentage'] as int,
      bonusAmount: json['bonus_amount'] as int,
      total: json['total'] as int,
      durationHumanized: json['duration_humanized'] as String,
    );
  }
}
