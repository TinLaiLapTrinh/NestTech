import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    SafeFrameWidget(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

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
    WidgetsBinding.instance.addTimingsCallback((timings) {
      // ❌ Bỏ qua lỗi debugFrameWasSentToEngine
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
