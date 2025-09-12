import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentQrScreen extends StatefulWidget {
  final String payUrl;
  final int orderId;

  const PaymentQrScreen({super.key, required this.payUrl, required this.orderId});

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      final status = await CheckoutService.checkPaymentStatus(widget.orderId);
      print(status);
      if (status == 'paid') {
        _timer?.cancel();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst); // về trang chủ
        }
      } else if (status == 'failed') {
        _timer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thanh toán thất bại!')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quét QR MoMo")),
      body: Center(
        child: QrImageView(
          data: widget.payUrl,
          version: QrVersions.auto,
          size: 250.0,
        ),
      ),
    );
  }
}
