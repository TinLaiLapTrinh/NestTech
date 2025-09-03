import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';

class OrderRequestScreen extends StatefulWidget {
  const OrderRequestScreen({super.key});

  @override
  State<OrderRequestScreen> createState() => _OrderRequestScreenState();
}

class _OrderRequestScreenState extends State<OrderRequestScreen> {
  List<dynamic> _myOrders = [];
  bool _isLoading = true;
  String? _selectedStatus;

  final List<String> filterStatuses = [
    "pending",
    "confirm",
    "processing",
    "cancelled",
    "shipped",
    "returned_to_sender",
    "refunded",
  ];

  final List<String> allowedUpdateStatuses = [
    "confirm",
    "processing",
    "cancelled",
    "shipped",
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      // Chuyển _selectedStatus thành Map params cho API
      Map<String, String>? params;
      if (_selectedStatus != null) {
        params = {"delivery_status": _selectedStatus!};
      }

      final items = await CheckoutService.orderRequest(params);
      setState(() {
        _myOrders = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi load orders request: $e");
    }
  }

  Future<dynamic> _updateStatusDelivery(int id, String status) async {
    try {
      print(status);
      final res = await CheckoutService.orderRequestUpdate(id, status);
      print(res);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi load orders request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yêu cầu đơn hàng")),
      body: Column(
        children: [
          // Thanh chọn trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: filterStatuses.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatus = isSelected ? null : status;
                        _loadOrders();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _myOrders.isEmpty
                ? const Center(child: Text("Bạn chưa có đơn hàng nào."))
                : ListView.builder(
                    itemCount: _myOrders.length,
                    itemBuilder: (context, index) {
                      final order = _myOrders[index];
                      final product = order['product_variant']['product'];
                      final optionValues =
                          order['product_variant']['option_values']
                              as List<dynamic>;

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            product['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: optionValues.map((opt) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Chip(
                                      label: Text(
                                        "${opt['option']['type']}: ${opt['value']}",
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                              ),
                              Text("Số lượng: ${order['quantity']}"),
                              Text("Giá: ${order['price']}"),
                              Text("Phí ship: ${order['delivery_charge']}"),
                              Text(
                                "Trạng thái hiện tại: ${order['delivery_status']}",
                              ),
                              const SizedBox(height: 4),

                              // Dropdown cập nhật trạng thái
                              DropdownButton<String>(
                                value: null,
                                hint: const Text("Cập nhật trạng thái"),
                                items: allowedUpdateStatuses.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    _updateStatusDelivery(
                                      order['id'],
                                      newStatus,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
