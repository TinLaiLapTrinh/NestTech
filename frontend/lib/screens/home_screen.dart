import 'package:flutter/material.dart';
import 'package:frontend/core/utils/token_storage.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/checkout/screens/cart_screen.dart';
import 'package:frontend/features/checkout/screens/order_request_screen.dart';
import 'package:frontend/features/checkout/screens/order_screen.dart';
import 'package:frontend/features/location/screens/map_screen.dart';
import 'package:frontend/features/product/screens/my_product_screen.dart';
import 'package:frontend/features/product/screens/product_list_screen.dart';
import 'package:frontend/features/shared/widgets/app_footer.dart';
import 'package:provider/provider.dart';

import '../features/user/provider/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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

    // Các trang cho customer
    final customerPages = [
      const ProductListScreen(),
      const MyCartItemsScreen(),
      const OrderScreen(),
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
    final pages = role == "supplier" ? supplierPages : customerPages;

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        isLoggedIn: isLoggedIn,
      ),
    );
  }
}
