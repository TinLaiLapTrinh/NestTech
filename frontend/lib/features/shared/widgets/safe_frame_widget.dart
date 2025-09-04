import 'package:flutter/material.dart';

class SafeFrameWidget extends StatefulWidget {
  final Widget child;

  const SafeFrameWidget({super.key, required this.child});

  @override
  State<SafeFrameWidget> createState() => _SafeFrameWidgetState();
}

class _SafeFrameWidgetState extends State<SafeFrameWidget> {
  @override
  void initState() {
    super.initState();
    // Ignore frame timing assertions in debug mode
    WidgetsBinding.instance.addTimingsCallback((timings) {
      // ❌ Chỉ debug: bỏ qua các frame spam
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
