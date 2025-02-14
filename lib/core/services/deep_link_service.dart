import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
      }
    });
  }

  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);

    // Handle different deep link paths
    switch (uri.path) {
      case '/orders':
        final orderId = uri.queryParameters['id'];
        if (orderId != null) {
          context.push('/orders/$orderId');
        }
        break;
      case '/payment':
        final status = uri.queryParameters['status'];
        final orderId = uri.queryParameters['order_id'];
        if (status == 'success' && orderId != null) {
          context.push('/orders/$orderId');
        }
        break;
      // Add more cases as needed
    }
  }
}
