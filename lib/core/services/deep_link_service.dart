import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:aina_flutter/core/router/app_router.dart';

class DeepLinkService {
  static const platform = MethodChannel('kz.aina/deep_links');
  final BuildContext context;

  DeepLinkService(this.context) {
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    print('🔧 Initializing DeepLinkService');
    platform.setMethodCallHandler((call) async {
      print('📱 Method channel called: ${call.method}');
      switch (call.method) {
        case 'handleDeepLink':
          final link = call.arguments as String;
          print('🔗 Received deep link: $link');
          _handleDeepLink(link);
          break;
        case 'appNotInstalled':
          print('📱 App not installed, redirecting to market');
          _redirectToMarket();
          break;
        default:
          print('⚠️ Unknown method: ${call.method}');
      }
    });
  }

  void _handleDeepLink(String link) {
    try {
      print('🔍 START _handleDeepLink with link: $link');
      final uri = Uri.parse(link);
      print('📦 Successfully parsed URI:');
      print('  - Scheme: ${uri.scheme}');
      print('  - Host: ${uri.host}');
      print('  - Path: ${uri.path}');
      print('  - Query: ${uri.queryParameters}');

      // Extract UTM parameters regardless of the path
      final utmSource = uri.queryParameters['utm_source'];
      final utmMedium = uri.queryParameters['utm_medium'];
      final utmCampaign = uri.queryParameters['utm_campaign'];

      print('📊 UTM Parameters:');
      print('  - Source: $utmSource');
      print('  - Medium: $utmMedium');
      print('  - Campaign: $utmCampaign');

      // Remove leading slash if present for easier comparison
      final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      print('🛣️ Normalized path: "$path"');

      if (path.isEmpty || path == 'deeplink') {
        print('🏠 Direct navigation to home triggered');
        _safeNavigate('/home');
      } else {
        print('🔄 Delegating to _navigateToPath');
        _navigateToPath(path, uri.queryParameters);
      }
    } catch (e, stackTrace) {
      print('❌ Error in _handleDeepLink:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      _safeNavigate('/home');
    }
  }

  void _safeNavigate(String path) {
    try {
      print('🚀 START _safeNavigate to path: $path');

      // Use the global router instance instead of context
      print('✅ Attempting navigation using global router');
      AppRouter.router.go(path);
      print('✨ Navigation completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error in _safeNavigate:');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      try {
        print('🔄 Attempting fallback navigation to /home');
        AppRouter.router.go('/home');
        print('✅ Fallback navigation successful');
      } catch (e2) {
        print('💥 Even fallback navigation failed: $e2');
      }
    }
  }

  Future<void> _redirectToMarket() async {
    final Uri marketUri;
    if (Platform.isIOS) {
      marketUri =
          Uri.parse('itms-apps://apps.apple.com/kz/app/aina/id6478210836');
    } else {
      marketUri = Uri.parse('market://details?id=kz.aina.android1');
    }

    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    } else {
      print('❌ Could not launch market URL');
    }
  }

  void _navigateToPath(String path, Map<String, String> params) {
    try {
      print('🎯 START _navigateToPath with path: $path');
      print('📝 Parameters: $params');

      switch (path) {
        case '':
        case 'home':
          print('🏠 Home path matched');
          _safeNavigate('/home');
          break;

        case 'deeplink':
          final targetUrl = params['url'];
          print('🔗 Deeplink path matched, target URL: $targetUrl');
          _safeNavigate('/home');
          break;

        case 'orders':
          final orderId = params['id'];
          if (orderId != null) {
            print('📦 Navigating to order: $orderId');
            _safeNavigate('/orders/$orderId');
          } else {
            print('⚠️ No order ID, going to orders list');
            _safeNavigate('/orders');
          }
          break;

        case 'payment':
          final status = params['status'];
          final orderId = params['order_id'];
          if (status == 'success' && orderId != null) {
            print('💳 Payment success, navigating to order: $orderId');
            _safeNavigate('/orders/$orderId');
          } else {
            print(
                '⚠️ Payment status not success or no order ID, going to home');
            _safeNavigate('/home');
          }
          break;

        // Handle success payment path
        case String p when p.startsWith('success-payment'):
          final orderId = params['order_id'];
          if (orderId != null) {
            print('💳 Payment success, navigating to order: $orderId');
            _safeNavigate('/orders/$orderId');
          } else {
            print('⚠️ Success payment but no order ID, going to home');
            _safeNavigate('/home');
          }
          break;

        // Handle failure payment path
        case String p when p.startsWith('failure-payment'):
          final orderId = params['order_id'];
          if (orderId != null) {
            print('❌ Payment failed, navigating to order: $orderId');
            _safeNavigate('/orders/$orderId');
          } else {
            print('⚠️ Failed payment but no order ID, going to home');
            _safeNavigate('/home');
          }
          break;

        default:
          print('⚠️ No specific path match, going to home');
          _safeNavigate('/home');
      }
    } catch (e, stackTrace) {
      print('❌ Error in _navigateToPath:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      _safeNavigate('/home');
    }
  }
}
