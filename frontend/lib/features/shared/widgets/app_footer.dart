import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role;
  final bool isLoggedIn;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items;

    if (role == "supplier") {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.store), label: "Sản phẩm"),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Sản phẩm của tôi"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Đơn hàng"),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: "Bản đồ"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
      ];
    } else if (role == "delivery_person") {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Thống kê"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Yêu cầu đơn"),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Đơn giao"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
      ];
    } else {
      // customer
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.store), label: "Sản phẩm"),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Giỏ hàng"),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Đơn hàng"),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: "Vị trí"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
      ];
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
      type: BottomNavigationBarType.fixed,
    );
  }
}
