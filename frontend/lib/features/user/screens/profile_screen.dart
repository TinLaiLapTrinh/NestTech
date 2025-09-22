import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:frontend/features/user/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndVerify(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      final file = File(picked.path);
      try {
        final response = await UserService.verification(file);
        final data = json.decode(response);
        if (data['verified'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Xác minh thành công")),
          );

          final userProvider = context.read<UserProvider>();
          final user = userProvider.currentUser;
          if (user != null) {
            user.isVerified = true; 
            userProvider.setUser(user);
          }
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: xác minh thất bại, căn cước không hợp lệ, vui lòng thử lại")));
      }
    }
  }

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
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: user.avatar != null && user.avatar!.isNotEmpty
                            ? Image.network(
                                user.avatar!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, size: 40);
                                },
                              )
                            : const Icon(Icons.person, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tên: ${user.firstName} ${user.lastName}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Email: ${user.email}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Địa chỉ: ${user.address ?? ''}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Số điện thoại: ${user.phoneNumber ?? ''}",
                    style: const TextStyle(fontSize: 16),
                  ),


                  if (user.userType == "supplier") ...[
                    const Divider(),
                    Text(
                      "Trạng thái xác minh: ${user.isVerified == true ? "✅ Đã xác minh" : "❌ Chưa xác minh"}",
                      style: TextStyle(
                        fontSize: 16,
                        color: user.isVerified == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (user.isVerified != true) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _pickAndVerify(context),
                        icon: const Icon(Icons.verified_user),
                        label: const Text("Xác minh CCCD"),
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      
                      userProvider.clearUser();
                      
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text("Đăng xuất"),
                  ),
                ],
              ),
            ),
    );
  }
}
