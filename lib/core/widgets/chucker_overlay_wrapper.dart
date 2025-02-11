import 'package:flutter/material.dart';

class ChuckerOverlayWrapper extends StatelessWidget {
  final Widget child;
  final bool showInRelease;

  const ChuckerOverlayWrapper({
    super.key,
    required this.child,
    this.showInRelease = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show if in debug mode or if showInRelease is true
    if (showInRelease || !const bool.fromEnvironment('dart.vm.product')) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            // const ChuckerFloatingButton(),
          ],
        ),
      );
    }
    return child;
  }
}
