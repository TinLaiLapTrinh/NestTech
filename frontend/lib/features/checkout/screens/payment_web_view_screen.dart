import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String payUrl;
  const PaymentWebViewScreen({super.key, required this.payUrl});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
       ..addJavaScriptChannel(
      'QRChannel',
      onMessageReceived: (message) {
        final qrBase64 = message.message;
        debugPrint("QR Base64: $qrBase64");
      },
    )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint("➡️ Start load: $url");
          },
          onPageFinished: (url) {
            debugPrint("✅ Finished load: $url");
          },
          onNavigationRequest: (request) {
            debugPrint("🌐 Nav request: ${request.url}");
            if (request.url.contains("/payments/return")) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán MoMo")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
