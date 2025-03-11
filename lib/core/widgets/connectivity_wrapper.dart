import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/connectivity_provider.dart';
import 'package:aina_flutter/features/general/no_internet/presentation/pages/no_internet_page.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasInternet = ref.watch(connectivityProvider);

    if (!hasInternet) {
      return const NoInternetPage();
    }

    return child;
  }
}
