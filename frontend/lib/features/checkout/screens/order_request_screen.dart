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
    "delivered",
    "returned_to_sender",
    "refunded",

  ];

  Map<String, List<String>> allowedTransitions = {
    "pending": ["confirm", "cancelled"],
    "confirm": ["processing", "cancelled"],
    "processing": ["shipped", "cancelled"],
    "shipped": ["delivered", "returned_to_sender"],
    "delivered": [],
    "returned_to_sender": [],
    "cancelled": [],
    "refunded": [],
  };

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
                      final productVariant = order['product'] ?? {};
                      final product = productVariant['product'] ?? {};
                      final optionValues =
                          productVariant['option_values'] is List
                          ? productVariant['option_values']
                          : [];

                      final routeInfo = order['route_info'] ?? {};
                      final from = routeInfo['from'] ?? {};
                      final to = routeInfo['to'] ?? {};

                      final currentStatus =
                          order['delivery_status'] ?? 'pending';
                      final nextStatuses =
                          allowedTransitions[currentStatus] ?? [];


                      Color statusColor(String status) {
                        switch (status.toLowerCase()) {
                          case 'pending':
                            return Colors.orange;
                          case 'confirm':
                            return Colors.blue;
                          case 'processing':
                            return Colors.teal;
                          case 'shipped':
                            return Colors.green;
                          case 'cancelled':
                            return Colors.red;
                          case 'returned_to_sender':
                            return Colors.purple;
                          case 'refunded':
                            return Colors.grey;
                          default:
                            return Colors.black;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hình ảnh + tên sản phẩm
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product['image'] ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      product['name'] ?? 'Không có tên',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Trạng thái với màu
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor(
                                        order['delivery_status'] ?? 'pending',
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order['delivery_status']?.toUpperCase() ??
                                          '',
                                      style: TextStyle(
                                        color: statusColor(
                                          order['delivery_status'] ?? 'pending',
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Option values
                              Wrap(
                                children: optionValues.map<Widget>((opt) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: 6.0,
                                      bottom: 4,
                                    ),
                                    child: Chip(
                                      label: Text(
                                        "${opt['option']?['type'] ?? ''}: ${opt['value'] ?? ''}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.grey[200],
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 4),
                              Text("Số lượng: ${order['quantity'] ?? 0}"),
                              Text("Giá: ${order['price'] ?? 0}"),
                              Text(
                                "Phí ship: ${order['delivery_charge'] ?? 0}",
                              ),
                              Text(
                                "Phương thức: ${order['delivery_method'] ?? ''}",
                              ),
                              Text(
                                "Người giao: ${order['delivery_person'] ?? 'Chưa có'}",
                              ),
                              const SizedBox(height: 8),

                              // Thông tin tuyến đường
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Tuyến đường:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Từ: ${from['address'] ?? ''}, ${from['ward'] ?? ''}, ${from['district'] ?? ''}, ${from['province'] ?? ''}",
                                    ),
                                    Text(
                                      "Đến: ${to['address'] ?? ''}, ${to['ward'] ?? ''}, ${to['district'] ?? ''}, ${to['province'] ?? ''}",
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
                              // Dropdown cập nhật trạng thái
                              if (nextStatuses.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  children: nextStatuses.map((status) {
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: statusColor(status),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () {
                                        _updateStatusDelivery(
                                          order['id'],
                                          status,
                                        );
                                      },
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                Text(
                                  "Không thể cập nhật trạng thái nữa",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
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
