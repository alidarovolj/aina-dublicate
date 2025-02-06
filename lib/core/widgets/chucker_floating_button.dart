import 'package:flutter/material.dart';
import 'package:chucker_flutter/chucker_flutter.dart';

class ChuckerFloatingButton extends StatelessWidget {
  const ChuckerFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 16,
      bottom: bottomPadding > 0 ? bottomPadding + 64 : 64,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.bug_report,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {
              ChuckerFlutter.showChuckerScreen();
            },
            tooltip: 'Show Network Logs',
          ),
        ),
      ),
    );
  }
}
