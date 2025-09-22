import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/screens/order_detail_screen.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';
import 'package:intl/intl.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> _myOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final items = await CheckoutService.getMyOrder();
      setState(() {
        _myOrders = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Lỗi load orders: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myOrders.isEmpty) {
      return const Center(child: Text("Bạn chưa có đơn hàng nào."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Đơn hàng của tôi")),
      body: ListView.builder(
        itemCount: _myOrders.length,
        itemBuilder: (context, index) {
          final order = _myOrders[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text("Đơn hàng #${order['id']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Trạng thái: ${order['delivery_status']}"),
                  Text("Tổng tiền: ${order['total']} VNĐ"),
                  Text(
                    "Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order['created_at']))}",
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: order['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}