import 'package:flutter/material.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart'
    show
        WebViewController,
        WebViewWidget,
        NavigationDelegate,
        JavaScriptMode,
        NavigationDecision;

class PaymentWebView extends StatefulWidget {
  final String htmlContent;
  final VoidCallback onClose;
  final Function(String) onNavigationRequest;

  const PaymentWebView({
    super.key,
    required this.htmlContent,
    required this.onClose,
    required this.onNavigationRequest,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final WebKitWebViewControllerCreationParams params =
        WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            debugPrint('Navigation request to: ${request.url}');
            final result = widget.onNavigationRequest(request.url);
            return result;
          },
          onPageFinished: (url) {
            debugPrint('Page finished loading: $url');
          },
          // Просто логируем ошибки без каких-либо действий
          onWebResourceError: (error) {
            debugPrint('Web resource error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'closePayment',
        onMessageReceived: (message) {
          debugPrint('Close payment requested');
          widget.onClose();
        },
      )
      ..loadHtmlString(widget.htmlContent,
          baseUrl: 'https://test-epay.homebank.kz');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
        ],
      ),
    );
  }
}
