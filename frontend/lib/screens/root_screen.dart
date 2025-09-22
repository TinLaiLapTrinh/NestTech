import 'package:flutter/material.dart';
import 'package:frontend/core/utils/token_storage.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _loading = true;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await TokenStorage.getToken();

    if (token != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchCurrentUser(token);
      _userType = userProvider.currentUser?.userType;
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userType == null) {
      
      return const LoginScreen();
    }

    if (_userType == "customer") {
      
      return const HomeScreen();
    }

    

    if (_userType == "supplier") {
      
      return const LoginScreen();
      
    }


    return const LoginScreen();
  }
}
