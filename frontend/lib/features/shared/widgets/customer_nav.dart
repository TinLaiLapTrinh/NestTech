import 'package:flutter/material.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/checkout/screens/cart_screen.dart';
import 'package:frontend/features/checkout/screens/order_screen.dart';
import 'package:frontend/features/product/screens/product_list_screen.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:frontend/features/user/screens/profile_screen.dart';
import 'package:provider/provider.dart';

class CustomerNav extends StatefulWidget {
  const CustomerNav({super.key});

  @override
  State<CustomerNav> createState() => _CustomerNavState();
}

class _CustomerNavState extends State<CustomerNav> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final screens = [
      const ProductListScreen(),
      const MyCartItemsScreen(),
      const OrderScreen(),
      // const NotificationScreen(),   // nếu sau này có màn thông báo thì thêm
      userProvider.isLoggedIn
          ? const ProfileScreen()   // đã login
          : const LoginScreen(),    // chưa login
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // để hiển thị nhiều item
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Sản phẩm"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Giỏ hàng"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Đơn hàng"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        ],
      ),
    );
  }
}
