import 'package:flutter/material.dart';

class DeliveryOrderDetailScreen extends StatelessWidget {
  final dynamic order;
  const DeliveryOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderDetails = order['order_details'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết đơn hàng")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Địa chỉ: ${order['address'] ?? 'Không có'}"),
            Text("SĐT: ${order['receiver_phone_number'] ?? 'Không có'}"),
            Text("Tổng tiền: ${order['total'] ?? '0'}"),
            const SizedBox(height: 12),
            const Text(
              "Sản phẩm:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...orderDetails.map((item) {
              final product = item["product"];
              final productInfo = product?["product"];
              final optionValues = product?["option_values"] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (productInfo?["image"] != null)
                            Image.network(
                              productInfo["image"],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              productInfo?["name"] ?? "Không có tên",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (optionValues.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: optionValues.map((opt) {
                            return Chip(
                              label: Text(
                                "${opt["option"]?["type"] ?? ""}: ${opt["value"] ?? ""}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      Text("Số lượng: ${item["quantity"] ?? 0}"),
                      Text("Giá: ${item["price"] ?? 0}"),
                      Text("Phí vận chuyển: ${item["delivery_charge"] ?? 0}"),
                      Text(
                        "Trạng thái: ${item["delivery_status"] ?? "pending"}",
                      ),
                      if (item["confirm_image"] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item["confirm_image"],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}