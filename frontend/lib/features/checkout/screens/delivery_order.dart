import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';

class DeliveryOrderScreen extends StatefulWidget {
  const DeliveryOrderScreen({super.key});

  @override
  State<DeliveryOrderScreen> createState() => _DeliveryOrderScreenState();
}

class _DeliveryOrderScreenState extends State<DeliveryOrderScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedStatus;

  final ScrollController _scrollController = ScrollController();

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
    _loadOrders(initial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadOrders();
      }
    });
  }

  Future<void> _loadOrders({bool initial = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    if (initial) {
      _currentPage = 1;
      _orders.clear();
      _hasMore = true;
    }

    try {
      final params = {
        if (_selectedStatus != null) "delivery_status": _selectedStatus!,
        "page": _currentPage.toString(),
      };

      final items = await CheckoutService.orderRequest(params);

      setState(() {
        if (items.isEmpty) {
          _hasMore = false;
        } else {
          _orders.addAll(items);
          _currentPage++;
        }
      });
    } catch (e) {
      debugPrint("Error loading orders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatusDelivery(int id, String status) async {
    try {
      await CheckoutService.orderRequestUpdate(id, status);
      
      _loadOrders(initial: true);
    } catch (e) {
      debugPrint("Failed to update order: $e");
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadOrders(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đơn hàng giao")),
      body: Column(
        children: [
          // Filter bằng ChoiceChip
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
                    onSelected: (_) =>
                        _onStatusFilterChanged(isSelected ? null : status),
                  ),
                );
              }).toList(),
            ),
          ),

          // List orders
          Expanded(
            child: _orders.isEmpty && !_isLoading
                ? const Center(child: Text("Không có đơn hàng"))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _orders.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _orders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final order = _orders[index];
                      final product = order['product_variant']['product'];
                      final optionValues =
                          order['product_variant']['option_values'] as List;

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeliveryOrderDetailScreen(order: order),
                              ),
                            );
                          },
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
                                          "${opt['option']['type']}: ${opt['value']}"),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                              ),
                              Text("Số lượng: ${order['quantity']}"),
                              Text("Giá: ${order['price']}"),
                              Text("Phí ship: ${order['delivery_charge']}"),
                              Text("Trạng thái: ${order['delivery_status']}"),
                              DropdownButton<String>(
                                hint: const Text("Cập nhật trạng thái"),
                                items: allowedUpdateStatuses.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (status) {
                                  if (status != null) {
                                    _updateStatusDelivery(order['id'], status);
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

// Chi tiết đơn hàng
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
                                  fontWeight: FontWeight.bold),
                            ),
                          )
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
                      Text("Trạng thái: ${item["delivery_status"] ?? "pending"}"),
                    ],
                  ),
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }
}
