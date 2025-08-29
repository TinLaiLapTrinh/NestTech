import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';

class MyCartItemsScreen extends StatefulWidget {
  const MyCartItemsScreen({super.key});
  @override
  State<MyCartItemsScreen> createState() => _MyCartItemsScreenState();
}

class _MyCartItemsScreenState extends State<MyCartItemsScreen> {
  List<dynamic> _myCartItems = [];
  bool _isLoading = true;

  // Map để lưu timer của từng item
  final Map<int, Timer?> _updateTimers = {};

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final items = await CheckoutService.getCartItems();
    setState(() {
      _myCartItems = items;
      _isLoading = false;
    });
  }

  void _scheduleUpdate(int itemId, int newQuantity) {
    // Hủy timer cũ nếu có
    _updateTimers[itemId]?.cancel();

    // Tạo timer mới: 3 giây sau gọi API update
    _updateTimers[itemId] = Timer(const Duration(seconds: 3), () async {
      try {
        await CheckoutService.updateCartItem(itemId, newQuantity);
        debugPrint("✅ Item $itemId updated với số lượng $newQuantity");
      } catch (e) {
        debugPrint("❌ Lỗi update item $itemId: $e");
      }
    });
  }

  void _changeQuantity(int index, int delta) {
    final item = _myCartItems[index];
    final newQuantity = (item['quantity'] as int) + delta;

    if (newQuantity <= 0) return; // không cho < 1

    setState(() {
      _myCartItems[index]['quantity'] = newQuantity;
    });

    // Schedule update sau 3 giây
    _scheduleUpdate(item['id'], newQuantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách sản phẩm")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _myCartItems.length,
              itemBuilder: (context, index) {
                final p = _myCartItems[index];
                final variant = p['product'];
                final baseProduct = variant['product'];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          (baseProduct['image']?.isNotEmpty ?? false)
                              ? baseProduct['image']
                              : "https://via.placeholder.com/100",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                baseProduct['name'] ?? 'Không tên',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: (variant['option_values'] as List)
                                    .map((opt) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2, horizontal: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            opt['value'],
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Giá: ${variant['price']}đ",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                "Kho: ${variant['stock']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _changeQuantity(index, -1),
                                  ),
                                  Text(
                                    "${p['quantity']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _changeQuantity(index, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
