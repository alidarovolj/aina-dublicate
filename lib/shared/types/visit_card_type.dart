import 'package:flutter/foundation.dart'; // Import this for VoidCallback

class VisitCardType {
  final String id;
  final String name;
  final String specialization;
  final int experience;
  final String location;
  // final String date;
  final String price;
  final String avatar;
  final double rating;
  final VoidCallback onDetails;
  final VoidCallback onReschedule;

  VisitCardType({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.location,
    // required this.date,
    required this.price,
    required this.avatar,
    required this.rating,
    required this.onDetails,
    required this.onReschedule,
  });
}
