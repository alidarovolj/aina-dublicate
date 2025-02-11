class CoworkingUserData {
  final String? companyName;
  final String? position;
  final String? workPhone;
  final String? workEmail;
  final String? workType;

  CoworkingUserData({
    this.companyName,
    this.position,
    this.workPhone,
    this.workEmail,
    this.workType,
  });

  factory CoworkingUserData.fromJson(Map<String, dynamic> json) {
    return CoworkingUserData(
      companyName: json['company_name'],
      position: json['position'],
      workPhone: json['work_phone'],
      workEmail: json['work_email'],
      workType: json['work_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'position': position,
      'work_phone': workPhone,
      'work_email': workEmail,
      'work_type': workType,
    };
  }
}
