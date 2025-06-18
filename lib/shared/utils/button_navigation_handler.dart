import 'package:aina_flutter/shared/types/button_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';

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

      // Check if user is authenticated when auth is required
      if (isAuthRequired) {
        final authState = ref.read(authProvider);
        if (!authState.isAuthenticated) {
          // User is not authenticated, redirect to login
          context.pushNamed('login');
          return;
        }
        // User is authenticated, continue with navigation
      }

      // Execute navigation logic
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
          context
              .pushNamed('news_details', pathParameters: {'id': id.toString()});
          break;
        case 'Service':
          // final build_id = internal.buildId;
          context.pushNamed('coworking_services',
              pathParameters: {'id': internal.buildId.toString()});
          break;
        case 'Category':
          // For Category model, navigate based on building_type
          final buildingType = internal.buildingType;
          final buildingId = internal.buildId;

          if (buildingType == 'coworking') {
            if (buildingId != null) {
              // Use building_id from internal if available
              context.pushNamed('coworking_services',
                  pathParameters: {'id': buildingId.toString()});
            } else {
              // If no building_id in internal, we need building context from promotion
              // This will be handled by the calling context providing buildingId
              debugPrint(
                  'Category navigation: building_id is null, need building context');
            }
          }
          break;
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
