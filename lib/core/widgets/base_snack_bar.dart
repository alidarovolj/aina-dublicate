import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  neutral,
  error,
}

class BaseSnackBar extends StatelessWidget {
  final String message;
  final SnackBarType type;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const BaseSnackBar({
    super.key,
    required this.message,
    this.type = SnackBarType.neutral,
    this.onActionPressed,
    this.actionLabel,
  });

  Color get iconColor {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFF4CAF50); // Material Green
      case SnackBarType.neutral:
        return const Color(0xFF2196F3); // Material Blue
      case SnackBarType.error:
        return const Color(0xFFF44336); // Material Red
    }
  }

  IconData get icon {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle;
      case SnackBarType.neutral:
        return Icons.info;
      case SnackBarType.error:
        return Icons.error;
    }
  }

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.neutral,
    VoidCallback? onActionPressed,
    String? actionLabel,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    final overlayEntry = OverlayEntry(
      builder: (context) => _SnackBarAnimation(
        duration: duration,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: mediaQuery.padding.bottom + keyboardHeight + 16,
              left: 16,
              right: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: BaseSnackBar(
                message: message,
                type: type,
                onActionPressed: onActionPressed,
                actionLabel: actionLabel,
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SnackBarAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _SnackBarAnimation({
    required this.child,
    required this.duration,
  });

  @override
  State<_SnackBarAnimation> createState() => _SnackBarAnimationState();
}

class _SnackBarAnimationState extends State<_SnackBarAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
