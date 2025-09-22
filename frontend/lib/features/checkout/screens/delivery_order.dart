import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/screens/confirm_img_order_delivery.dart';
import 'package:frontend/features/checkout/screens/delivery_detail_order.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';
import 'package:image_picker/image_picker.dart';

class DeliveryOrderScreen extends StatefulWidget {
  const DeliveryOrderScreen({super.key});

  @override
  State<DeliveryOrderScreen> createState() => _DeliveryOrderScreenState();
}

class _DeliveryOrderScreenState extends State<DeliveryOrderScreen> {
  final List<dynamic> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedStatus;

  final ScrollController _scrollController = ScrollController();

  final List<String> filterStatuses = [
    "shipped",
    "returned_to_sender",
    "delivered",
    "refunded",
  ];

  final List<String> allowedUpdateStatuses = [
    "delivered",
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onStatusChanged(int orderId, String newStatus) async {
    if (newStatus == "delivered") {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bạn phải chọn ảnh để xác nhận giao hàng"),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final uploadRes = await CheckoutService.orderConfirmImage(
        orderId,
        File(picked.path),
      );

      if (uploadRes['success'] == true) {
        final res = await CheckoutService.orderRequestUpdate(
          orderId,
          newStatus,
        );

        if (res['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cập nhật trạng thái thành công")),
          );
          _loadOrders(initial: true);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi khi cập nhật trạng thái")),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Upload ảnh thất bại")));
      }

      if (mounted) setState(() => _isLoading = false);
    } else {
      final res = await CheckoutService.orderRequestUpdate(orderId, newStatus);
      if (res['success'] == true) {
        _loadOrders(initial: true);
      }
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadOrders(initial: true);
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'shipped':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'returned_to_sender':
        return Colors.purple;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.black;
    }
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
                      final product = order['product']['product'];
                      final optionValues =
                          order['product']['option_values'] as List;
                      final routeInfo = order['route_info'];
                      final from = routeInfo?['from'] ?? {};
                      final to = routeInfo?['to'] ?? {};

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product['image'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      product['name'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.map),
                                    color: Colors.blue,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DeliveryDetailScreen(
                                            orderId: order['id'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
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
                              const SizedBox(height: 4),
                              Text("Số lượng: ${order['quantity']}"),
                              Text("Giá: ${order['price']}"),
                              Text("Phí ship: ${order['delivery_charge']}"),
                              const SizedBox(height: 4),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor(
                                    order['delivery_status'],
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order['delivery_status']?.toUpperCase() ?? '',
                                  style: TextStyle(
                                    color: statusColor(
                                      order['delivery_status'],
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              
                              DropdownButton<String>(
                                hint: const Text("Cập nhật trạng thái"),
                                value: null,
                                items: allowedUpdateStatuses.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged:
                                    order['delivery_status'] == 'delivered'
                                    ? null
                                    : (status) async {
                                        if (status == null) return;

                                        if (status == "delivered") {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ConfirmDeliveryScreen(
                                                    orderDetailId: order['id'],
                                                  ),
                                            ),
                                          );

                                          if (result == true) {
                                            _loadOrders(initial: true);
                                          }
                                        } else {
                                          setState(() => _isLoading = true);
                                          try {
                                            await CheckoutService.orderRequestUpdate(
                                              order['id'],
                                              status,
                                            );
                                            _loadOrders(initial: true);
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Lỗi khi cập nhật trạng thái",
                                                  ),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted)
                                              setState(
                                                () => _isLoading = false,
                                              );
                                          }
                                        }
                                      },
                                disabledHint: const Text(
                                  "Đơn hàng đã giao, không thể cập nhật",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
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
