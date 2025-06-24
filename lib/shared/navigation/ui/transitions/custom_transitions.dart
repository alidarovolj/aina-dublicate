import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom page transitions for the app
class CustomPageTransitions {
  /// Slide transition from right to left
  static CustomTransitionPage<void> slideTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Slide transition with custom direction
  /// [fromRight] - if true, slides from right to left, if false - from left to right
  static CustomTransitionPage<void> directionalSlideTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    required bool fromRight,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    // Debug: Анимация создается (только для новых переходов с extra данными)
    if (state.extra != null) {
      debugPrint('🎬 CREATING DIRECTIONAL SLIDE ANIMATION:');
      debugPrint('   Route: ${state.uri}');
      debugPrint('   Direction: ${fromRight ? 'FROM RIGHT →' : 'FROM LEFT ←'}');
      debugPrint('   Duration: ${duration.inMilliseconds}ms');
      debugPrint('   Curve: $curve');
    }

    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(fromRight ? 1.0 : -1.0, 0.0);
        const end = Offset.zero;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        // Debug: Анимация началась (только для новых переходов)
        if (state.extra != null) {
          bool hasListener = false;
          try {
            animation.addStatusListener((status) {
              if (!hasListener) {
                hasListener = true;
                if (status == AnimationStatus.forward) {
                  debugPrint('   ▶️ Animation started: ${state.uri}');
                } else if (status == AnimationStatus.completed) {
                  debugPrint('   ✅ Animation completed: ${state.uri}');
                }
              }
            });
          } catch (e) {
            // Игнорируем ошибки добавления listener'а
          }
        }

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Fade transition
  static CustomTransitionPage<void> fadeTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    // Debug: Fade анимация создается
    debugPrint('🌟 CREATING FADE ANIMATION:');
    debugPrint('   Route: ${state.uri}');
    debugPrint('   Duration: ${duration.inMilliseconds}ms');
    debugPrint('   Curve: $curve');

    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Debug: Fade анимация началась (добавляем listener только если его еще нет)
        bool hasListener = false;
        try {
          animation.addStatusListener((status) {
            if (!hasListener) {
              hasListener = true;
              if (status == AnimationStatus.forward) {
                debugPrint('   ▶️ Fade animation started: ${state.uri}');
              } else if (status == AnimationStatus.completed) {
                debugPrint('   ✅ Fade animation completed: ${state.uri}');
              }
            }
          });
        } catch (e) {
          // Игнорируем ошибки добавления listener'а
        }

        return FadeTransition(
          opacity: CurveTween(curve: curve).animate(animation),
          child: child,
        );
      },
    );
  }

  /// Combined slide and fade transition
  static CustomTransitionPage<void> slideWithFadeTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    required bool fromRight,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    // Debug: Комбинированная анимация создается
    debugPrint('🎭 CREATING SLIDE + FADE ANIMATION:');
    debugPrint('   Route: ${state.uri}');
    debugPrint('   Direction: ${fromRight ? 'FROM RIGHT →' : 'FROM LEFT ←'}');
    debugPrint('   Duration: ${duration.inMilliseconds}ms');
    debugPrint('   Curve: $curve');

    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(fromRight ? 1.0 : -1.0, 0.0);
        const end = Offset.zero;

        var slideAnimation = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve))
            .animate(animation);

        var fadeAnimation = CurveTween(curve: curve).animate(animation);

        // Debug: Slide+Fade анимация началась (добавляем listener только если его еще нет)
        bool hasListener = false;
        try {
          animation.addStatusListener((status) {
            if (!hasListener) {
              hasListener = true;
              if (status == AnimationStatus.forward) {
                debugPrint('   ▶️ Slide+Fade animation started: ${state.uri}');
              } else if (status == AnimationStatus.completed) {
                debugPrint('   ✅ Slide+Fade animation completed: ${state.uri}');
              }
            }
          });
        } catch (e) {
          // Игнорируем ошибки добавления listener'а
        }

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
