import 'package:flutter/material.dart';

class CoworkingBookingsPage extends StatelessWidget {
  final int coworkingId;

  const CoworkingBookingsPage({
    super.key,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Text('Coworking Bookings #$coworkingId'),
        ),
      ),
    );
  }
}
