import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';
import 'package:intl/intl.dart';

class OrderRequestScreen extends StatefulWidget {
  const OrderRequestScreen({super.key});

  @override
  State<OrderRequestScreen> createState() => _OrderRequestScreenState();
}

class _OrderRequestScreenState extends State<OrderRequestScreen> {
  List<dynamic> _myOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final items = await CheckoutService.orderRequest();
      setState(() {
        _myOrders = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Lỗi load orders request: $e");
    }
  }

  String formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(price);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_myOrders.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Bạn chưa có đơn hàng nào.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Yêu cầu đơn hàng")),
      body: ListView.builder(
        itemCount: _myOrders.length,
        itemBuilder: (context, index) {
          final order = _myOrders[index];

          final product = order['product_variant']['product'];
          final optionValues = order['product_variant']['option_values'] as List<dynamic>;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  order['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(product['name'], maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    children: optionValues.map((opt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Chip(
                          label: Text("${opt['option']['type']}: ${opt['value']}"),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                  Text("Số lượng: ${order['quantity']}"),
                  Text("Giá: ${formatPrice(order['price'])}"),
                  Text("Phí ship: ${formatPrice(order['delivery_charge'])}"),
                  Text("Trạng thái: ${order['delivery_status']}"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  // ví dụ cập nhật trạng thái thành cancelled
                  await CheckoutService.orderRequestUpdate(order['id'], "cancelled");
                  _loadOrders();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
