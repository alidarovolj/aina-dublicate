import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/update_notifier_provider.dart';
import 'package:aina_flutter/core/widgets/update_modal.dart';

class UpdateOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<UpdateOverlay> createState() => _UpdateOverlayState();
}

class _UpdateOverlayState extends ConsumerState<UpdateOverlay> {
  bool _showUpdateModal = false;
  bool _isSplashScreen = true;

  @override
  void initState() {
    super.initState();
    // Отложенная проверка для показа модального окна после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Даем время для перехода со Splash Screen (обычно 2-3 секунды)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSplashScreen = false;
            _checkIfShouldShowUpdateModal();
          });
        }
      });
    });
  }

  void _checkIfShouldShowUpdateModal() {
    if (!mounted) return;

    try {
      final updateState = ref.read(updateNotifierProvider);
      if (updateState.type != UpdateType.none) {
        if (mounted) {
          setState(() {
            _showUpdateModal = true;
          });
        }
      }
    } catch (e) {
      // Handle any errors that might occur when reading the provider
      print('Error checking update state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return widget.child;

    UpdateNotifierState? updateState;
    try {
      updateState = ref.watch(updateNotifierProvider);
    } catch (e) {
      // Handle any errors that might occur when watching the provider
      print('Error watching update state: $e');
      return widget.child;
    }

    // Не показываем модальное окно на Splash Screen
    final shouldShowModal = _showUpdateModal &&
        !_isSplashScreen &&
        updateState != null &&
        updateState.type != UpdateType.none;

    return Stack(
      children: [
        widget.child,
        if (shouldShowModal)
          WillPopScope(
            onWillPop: () async {
              // Prevent closing the modal with back button for hard updates
              return updateState?.type != UpdateType.hard;
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: const UpdateModal(),
              ),
            ),
          ),
      ],
    );
  }
}
