import 'package:flutter/material.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin cá nhân")),
      body: user == null
          ? const Center(child: Text("Bạn chưa đăng nhập"))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tên: ${user.firstName} ${user.lastName}",
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("Email: ${user.email}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Địa chỉ: ${user.address ?? ''}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Số điện thoại: ${user.phoneNumber ?? ''}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      userProvider.clearUser();
                      Navigator.pop(context);
                    },
                    child: const Text("Đăng xuất"),
                  ),
                ],
              ),
            ),
    );
  }
}
