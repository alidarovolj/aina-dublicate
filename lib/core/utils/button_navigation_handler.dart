import 'package:aina_flutter/core/types/button_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import your auth provider

class ButtonNavigationHandler {
  static Future<void> handleNavigation(
    BuildContext context,
    WidgetRef ref,
    ButtonConfig? button,
  ) async {
    if (button == null) return;

    if (button.isInternal == false) {
      if (button.link != null) {
        // Handle external link - you might want to use url_launcher package
        // await launchUrl(Uri.parse(button.link));
      }
      return;
    }

    final internal = button.internal;
    if (internal != null) {
      final model = internal.model;
      final id = internal.id;
      final isAuthRequired = internal.isAuthRequired;

      // Check auth if required
      // final isAuthed = ref.read(authProvider).isAuthenticated;
      const isAuthed = true; // Replace with actual auth check

      if (!isAuthRequired || isAuthed) {
        switch (model) {
          case 'Promotion':
            // Fetch promotion data if needed
            // await ref.read(promotionProvider.notifier).fetchPromotion(id);

            // Navigate based on type
            if (internal.isQr == true) {
              context.pushNamed('promotion_scanner',
                  pathParameters: {'id': id.toString()});
            } else {
              context.pushNamed('promotion_details',
                  pathParameters: {'id': id.toString()});
            }
            break;

          case 'Event':
            // Fetch event data if needed
            // await ref.read(eventProvider.notifier).fetchEvent(id);
            context.pushNamed('event_details',
                pathParameters: {'id': id.toString()});
            break;

          case 'News':
            context.pushNamed('news_details',
                pathParameters: {'id': id.toString()});
            break;
        }
      } else {
        // Redirect to profile/auth if needed
        context.pushNamed('profile');
      }
    }
  }
}
