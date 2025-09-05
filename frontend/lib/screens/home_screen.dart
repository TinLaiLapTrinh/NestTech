import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/token_storage.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/checkout/screens/cart_screen.dart';
import 'package:frontend/features/checkout/screens/order_request_screen.dart';
import 'package:frontend/features/checkout/screens/order_screen.dart';
import 'package:frontend/features/location/screens/location_manager_screen.dart';
import 'package:frontend/features/location/screens/map_screen.dart';
import 'package:frontend/features/product/screens/my_product_screen.dart';
import 'package:frontend/features/product/screens/product_list_screen.dart';
import 'package:frontend/features/shared/widgets/app_footer.dart';
import 'package:frontend/features/stats/screens/stats_screen.dart';
import 'package:frontend/features/user/screens/profile_screen.dart';
import 'package:frontend/features/user/services/user_service.dart';
import 'package:provider/provider.dart';

import '../features/user/provider/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  void _setupFcm() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await UserService().saveFcmToken(fcmToken);
          print("FCM token sent: $fcmToken");
        }
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          "Foreground notification: ${message.notification?.title} - ${message.notification?.body}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked: ${message.data}");
    });
  }

  void _logout(UserProvider userProvider) async {
    await TokenStorage.clearToken();
    userProvider.clearUser();
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.currentUser != null;
    final role = userProvider.currentUser?.userType ?? "customer";

    // Pages theo role
    final supplierPages = [
      const ProductListScreen(),
      const MyProductListScreen(),
      const OrderRequestScreen(),
      const MapFilterScreen(),
      const ProfileScreen(),
      if (isLoggedIn)
        _buildWelcomeWidget("Supplier", userProvider)
      else
        const LoginScreen(),
    ];

    final deliveryPages = [
      StatsScreen(),
      const OrderRequestScreen(),
      const OrderRequestScreen(),
      const ProfileScreen(),
      if (isLoggedIn)
        _buildWelcomeWidget("Delivery Person", userProvider)
      else
        const LoginScreen(),
    ];

    final customerPages = [
      const ProductListScreen(),
      const MyCartItemsScreen(),
      const OrderScreen(),
      const LocationManagerScreen(),
      const ProfileScreen(),
      if (isLoggedIn)
        _buildWelcomeWidget("Customer", userProvider)
      else
        const LoginScreen(),
    ];

    // Chọn pages theo role
    final pages = role == "supplier"
        ? supplierPages
        : role == "delivery_person"
            ? deliveryPages
            : customerPages;

    // Bảo vệ _currentIndex luôn hợp lệ
    final currentPage =
        (_currentIndex < pages.length) ? pages[_currentIndex] : pages[0];

    return Scaffold(
      body: currentPage,
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex < pages.length ? _currentIndex : 0,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        role: role,
        isLoggedIn: isLoggedIn,
      ),
    );
  }

  Widget _buildWelcomeWidget(String roleName, UserProvider userProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Xin chào $roleName"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _logout(userProvider),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }
}
