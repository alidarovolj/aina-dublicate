import 'package:flutter/material.dart';

class CoworkingProfilePage extends StatelessWidget {
  final int coworkingId;

  const CoworkingProfilePage({
    super.key,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Text('Coworking Profile #$coworkingId'),
        ),
      ),
    );
  }
}
