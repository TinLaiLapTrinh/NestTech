import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/checkout_service.dart';

class ConfirmDeliveryScreen extends StatefulWidget {
  final int orderDetailId;
  const ConfirmDeliveryScreen({super.key, required this.orderDetailId});

  @override
  State<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submitConfirm() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ảnh xác nhận")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      
      await CheckoutService.orderConfirmImage(widget.orderDetailId, _image!);
      
      await CheckoutService.orderRequestUpdate(
        widget.orderDetailId,
        "delivered",
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xác nhận giao hàng thành công!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác nhận giao hàng")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Chụp ảnh"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text("Thư viện"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_image != null)
              Expanded(child: Image.file(_image!, fit: BoxFit.contain)),
            const SizedBox(height: 12),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitConfirm,
                    child: const Text("Xác nhận giao hàng"),
                  ),
          ],
        ),
      ),
    );
  }
}
