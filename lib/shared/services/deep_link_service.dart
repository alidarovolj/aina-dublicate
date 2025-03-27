import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:aina_flutter/processes/navigation/index.dart';

class DeepLinkService {
  static const platform = MethodChannel('kz.aina/deep_links');
  final BuildContext context;

  DeepLinkService(this.context) {
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'handleDeepLink':
          final link = call.arguments as String;
          _handleDeepLink(link);
          break;
        case 'appNotInstalled':
          _redirectToMarket();
          break;
        default:
          debugPrint('⚠️ Unknown method: ${call.method}');
      }
    });
  }

  void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);

      // Remove leading slash if present for easier comparison
      final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;

      if (path.isEmpty || path == 'deeplink') {
        _safeNavigate('/home');
      } else {
        _navigateToPath(path, uri.queryParameters);
      }
    } catch (e) {
      _safeNavigate('/home');
    }
  }

  void _safeNavigate(String path) {
    try {
      // Use the global router instance instead of context
      RouterService.router.go(path);
    } catch (e) {
      debugPrint('Error: $e');

      try {
        RouterService.router.go('/home');
      } catch (e2) {
        debugPrint('💥 Even fallback navigation failed: $e2');
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
      debugPrint('❌ Could not launch market URL');
    }
  }

  void _navigateToPath(String path, Map<String, String> params) {
    try {
      switch (path) {
        case '':
        case 'home':
          _safeNavigate('/home');
          break;

        case 'deeplink':
          _safeNavigate('/home');
          break;

        case 'orders':
          final orderId = params['id'];
          if (orderId != null) {
            _safeNavigate('/orders/$orderId');
          } else {
            _safeNavigate('/orders');
          }
          break;

        case 'payment':
          final status = params['status'];
          final orderId = params['order_id'];
          if (status == 'success' && orderId != null) {
            _safeNavigate('/orders/$orderId');
          } else {
            _safeNavigate('/home');
          }
          break;

        // Handle success payment path
        case String p when p.startsWith('success-payment'):
          final orderId = params['order_id'];
          if (orderId != null) {
            _safeNavigate('/orders/$orderId');
          } else {
            _safeNavigate('/home');
          }
          break;

        // Handle failure payment path
        case String p when p.startsWith('failure-payment'):
          final orderId = params['order_id'];
          if (orderId != null) {
            _safeNavigate('/orders/$orderId');
          } else {
            _safeNavigate('/home');
          }
          break;

        default:
          _safeNavigate('/home');
      }
    } catch (e) {
      _safeNavigate('/home');
    }
  }
}
