import 'package:flutter/material.dart';

class CoworkingDetailsPage extends StatelessWidget {
  final int id;

  const CoworkingDetailsPage({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Text('Coworking Details #$id'),
        ),
      ),
    );
  }
}
