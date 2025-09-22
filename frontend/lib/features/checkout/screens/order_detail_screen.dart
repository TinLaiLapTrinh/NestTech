import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _orderDetail;
  bool _isLoading = true;
  final Map<int, double> _ratings = {}; // lưu rate theo order_detail_id
  final Map<int, TextEditingController> _commentCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    try {
      final detail = await CheckoutService.orderDetail(widget.orderId);
      setState(() {
        _orderDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi load order detail: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRate(int orderDetailId) async {
    final rating = _ratings[orderDetailId] ?? 0;
    final content = _commentCtrls[orderDetailId]?.text ?? "";

    if (rating == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn số sao")));
      return;
    }

    try {
      await CheckoutService.ratingProduct(orderDetailId, rating, content);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đánh giá thành công!")));
    } catch (e) {
      debugPrint("Lỗi gửi đánh giá: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_orderDetail == null) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy đơn hàng.")),
      );
    }

    final orderDetails = _orderDetail!["order_details"] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết đơn hàng")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Địa chỉ: ${_orderDetail!["address"] ?? "Không có"}"),
            Text(
              "SĐT: ${_orderDetail!["receiver_phone_number"] ?? "Không có"}",
            ),
            Text("Tổng tiền: ${_orderDetail!["total"] ?? "0"}"),
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
              final deliveryStatus = item["delivery_status"];
              final orderDetailId = item["id"];

              _commentCtrls.putIfAbsent(
                orderDetailId,
                () => TextEditingController(),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ảnh + tên
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // option values
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
                      Text("Trạng thái: ${deliveryStatus ?? "pending"}"),

                      // nếu đã giao hàng thì cho đánh giá
                      if (deliveryStatus == "delivered") ...[
                        const Divider(),
                        const Text(
                          "Đánh giá sản phẩm:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RatingBar.builder(
                          initialRating: _ratings[orderDetailId] ?? 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 28,
                          itemPadding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                          ),
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _ratings[orderDetailId] = rating;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentCtrls[orderDetailId],
                          decoration: const InputDecoration(
                            labelText: "Nhận xét của bạn",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _submitRate(orderDetailId),
                          child: const Text("Gửi đánh giá"),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
