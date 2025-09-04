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
import 'package:frontend/features/user/services/user_service.dart';
import 'package:provider/provider.dart';

import '../features/user/provider/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await UserService().saveFcmToken(fcmToken);
          print("FCM token sent from HomeScreen: $fcmToken");
        }
      }
    });

    // Lắng nghe notification foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        "Foreground notification: ${message.notification?.title} - ${message.notification?.body}",
      );
    });

    // Lắng nghe khi click notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked: ${message.data}");
    });
  }

  int _currentIndex = 0;

  void _logout(UserProvider userProvider) async {
    await TokenStorage.clearToken();
    userProvider.clearUser();
    setState(() {
      _currentIndex = 0; // reset về customer
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.currentUser != null;
    final role =
        userProvider.currentUser?.userType ?? "customer"; // mặc định customer

    // Các trang cho supplier
    final supplierPages = [
      const ProductListScreen(),
      const MyProductListScreen(),
      const OrderRequestScreen(),
      const MapFilterScreen(),
      isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Xin chào Supplier"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _logout(userProvider),
                    child: const Text("Đăng xuất"),
                  ),
                ],
              ),
            )
          : const LoginScreen(),
    ];

    // Các trang cho delivery person
    final deliveryPages = [
      StatsScreen(),
      const OrderRequestScreen(),
      const OrderRequestScreen(),
      isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Xin chào Delivery Person"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _logout(userProvider),
                    child: const Text("Đăng xuất"),
                  ),
                ],
              ),
            )
          : const LoginScreen(),
    ];

    // Các trang cho customer
    final customerPages = [
      const ProductListScreen(),
      const MyCartItemsScreen(),
      const OrderScreen(),
      const LocationManagerScreen(),
      isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Xin chào Customer"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _logout(userProvider),
                    child: const Text("Đăng xuất"),
                  ),
                ],
              ),
            )
          : const LoginScreen(),
    ];

    // Chọn danh sách trang theo role
    final pages = role == "supplier"
        ? supplierPages
        : role == "delivery_person"
        ? deliveryPages
        : customerPages; // default customer

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
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
}
