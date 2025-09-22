import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:frontend/features/user/screens/supplier_register_screen.dart';
import 'package:frontend/features/user/services/user_service.dart';
import 'package:provider/provider.dart';

import '../../../screens/home_screen.dart';
import '../../user/screens/user_register_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late UserProvider userProvider;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      userProvider: userProvider,
    );

    setState(() => _isLoading = false);

    if (success) {
      widget.onLoginSuccess?.call();
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await UserService().saveFcmToken(fcmToken);
        print("FCM token sent after login: $fcmToken");
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = "Sai tên đăng nhập hoặc mật khẩu!";
      });
    }
  }

  Future<String?> getFcmToken() async {
  String? token = await _firebaseMessaging.getToken();
  print("FCM Token: $token");
  return token;
}

  void _navigateToRegister() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chọn loại tài khoản",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserRegisterScreen(),
                    ),
                  );
                },
                child: const Text("Đăng ký tài khoản thường"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupplierRegisterScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Đăng ký tài khoản nhà cung cấp"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Tên đăng nhập"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Đăng nhập"),
            ),
            const SizedBox(height: 15),
            // Nút chuyển sang đăng ký
            TextButton(
              onPressed: _navigateToRegister,
              child: const Text(
                "Chưa có tài khoản? Đăng ký ngay",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
