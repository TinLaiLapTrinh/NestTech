import 'package:flutter/material.dart';
import 'package:frontend/features/product/screens/my_product_screen.dart';
import 'package:frontend/features/product/screens/product_list_screen.dart';
import 'package:frontend/features/user/screens/profile_screen.dart';

class SupplierNav extends StatefulWidget {
  const SupplierNav({super.key});

  @override
  State<SupplierNav> createState() => _SupplierNavState();
}

class _SupplierNavState extends State<SupplierNav> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ProductListScreen(),
      const MyProductListScreen(),
      const ProfileScreen(),   
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Sản phẩm của tôi"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        ],
      ),
    );
  }
}
