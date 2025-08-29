import 'package:flutter/material.dart';
import 'package:frontend/features/user/models/user_register_model.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:provider/provider.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isLoggedIn;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isLoggedIn,
  });

  List<BottomNavigationBarItem> _buildNavItems(UserModel? current, bool isLoggedIn) {
    if (current != null && current.userType == "supplier") {
      // Supplier navigation
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Trang chủ",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: "Sản phẩm của tôi",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: "Đơn hàng",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: "gg map",
        ),
        BottomNavigationBarItem(
          icon: Icon(isLoggedIn ? Icons.person : Icons.login),
          label: isLoggedIn ? "Cá nhân" : "Đăng nhập",
        ),
      ];
    } else {
      // Customer navigation
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Trang chủ",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: "Giỏ hàng",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: "Đơn hàng",
        ),
         const BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: "Quản lý vị trí",
        ),
        BottomNavigationBarItem(
          icon: Icon(isLoggedIn ? Icons.person : Icons.login),
          label: isLoggedIn ? "Cá nhân" : "Đăng nhập",
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    final isLoggedIn = currentUser != null;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: _buildNavItems(currentUser, isLoggedIn),
    );
  }
}
