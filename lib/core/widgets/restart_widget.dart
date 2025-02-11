import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    print('RestartWidget: Attempting to restart app...');
    final state = context.findAncestorStateOfType<_RestartWidgetState>();
    if (state != null) {
      print('RestartWidget: Found state, calling restartApp()');
      state.restartApp();
    } else {
      print('RestartWidget: No state found, restart failed');
    }
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() async {
    print('RestartWidget: Starting restart process');
    // Get the current locale before restart
    final currentLocale = context.locale;

    setState(() {
      print('RestartWidget: Generating new key and triggering rebuild');
      _key = UniqueKey();
    });

    // Ensure the locale is preserved after restart
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted && context.locale != currentLocale) {
      print('RestartWidget: Restoring locale');
      context.setLocale(currentLocale);
    }
    print('RestartWidget: Restart complete');
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
