import 'package:aina_flutter/core/types/button_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
// Import your auth provider

class ButtonNavigationHandler {
  static void handleNavigation(
    BuildContext context,
    WidgetRef ref,
    ButtonConfig? config,
  ) {
    if (config == null) return;

    if (config.isInternal == true && config.internal != null) {
      _handleInternalNavigation(context, ref, config);
    } else if (config.link != null) {
      _handleExternalNavigation(config.link!);
    }
  }

  static Future<void> _handleInternalNavigation(
    BuildContext context,
    WidgetRef ref,
    ButtonConfig config,
  ) async {
    final internal = config.internal;
    if (internal != null) {
      final model = internal.model;
      final id = internal.id;
      if (id == null) return; // Skip navigation if id is null

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

  static Future<void> _handleExternalNavigation(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
