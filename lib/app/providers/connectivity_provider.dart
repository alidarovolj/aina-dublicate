import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  StreamSubscription<ConnectivityResult>? _subscription;

  Future<void> _init() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    state = result != ConnectivityResult.none;

    _subscription = connectivity.onConnectivityChanged.listen((result) {
      if (!mounted) return;
      state = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
