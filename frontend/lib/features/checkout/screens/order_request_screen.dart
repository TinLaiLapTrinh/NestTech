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

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final _hideDone = true;
    setState(() => _isLoading = true);
    try {
      Map<String, String> params = {
        "hide_done": (_hideDone ?? true).toString(), // true/false
      };
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải đơn hàng: $e")));
    }
  }

  Future<void> _updateStatusDelivery(int id, String status) async {
    try {
      final res = await CheckoutService.orderRequestUpdate(id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã cập nhật trạng thái thành $status")),
      );
      _loadOrders(); // Reload orders after update
    } catch (e) {
      debugPrint("Lỗi cập nhật trạng thái: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
    }
  }

  String _getStatusText(String status) {
    final statusMap = {
      "pending": "Chờ xác nhận",
      "confirm": "Đã xác nhận",
      "processing": "Đang xử lý",
      "shipped": "Đang giao",
      "delivered": "Đã giao",
      "cancelled": "Đã hủy",
      "returned_to_sender": "Trả hàng",
      "refunded": "Đã hoàn tiền",
    };
    return statusMap[status] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirm':
        return Colors.blue;
      case 'processing':
        return Colors.teal;
      case 'shipped':
        return Colors.green;
      case 'delivered':
        return Colors.green.shade700;
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirm':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.build_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.assignment_turned_in;
      case 'cancelled':
        return Icons.cancel;
      case 'returned_to_sender':
        return Icons.keyboard_return;
      case 'refunded':
        return Icons.money_off;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý đơn hàng"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Bộ lọc trạng thái
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    "Lọc theo: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  ...filterStatuses.map((status) {
                    final isSelected = _selectedStatus == status;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getStatusText(status)),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = isSelected ? null : status;
                            _loadOrders();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: _getStatusColor(status).withOpacity(0.2),
                        checkmarkColor: _getStatusColor(status),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? _getStatusColor(status)
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected
                                ? _getStatusColor(status)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Thống kê nhanh
          if (_myOrders.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        _myOrders.length.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text("Tổng đơn", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _myOrders
                            .where((o) => o['delivery_status'] == 'pending')
                            .length
                            .toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const Text(
                        "Chờ xác nhận",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _myOrders
                            .where((o) => o['delivery_status'] == 'shipped')
                            .length
                            .toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const Text("Đang giao", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _myOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Không có đơn hàng nào",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_selectedStatus != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedStatus = null;
                              });
                              _loadOrders();
                            },
                            child: const Text("Xóa bộ lọc"),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
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
                        final recieveInfo = order['recieve_info'] ?? {};

                        final currentStatus =
                            order['delivery_status'] ?? 'pending';
                        final nextStatuses =
                            allowedTransitions[currentStatus] ?? [];

                        final orderDate = order['created_at'] != null
                            ? DateTime.parse(order['created_at'])
                            : null;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header với mã đơn hàng và ngày
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Mã đơn: #${order['id']?.toString() ?? 'N/A'}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (orderDate != null)
                                      Text(
                                        "${orderDate.day}/${orderDate.month}/${orderDate.year}",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Thông tin sản phẩm
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product['image'] ?? '',
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? 'Không có tên',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Thuộc tính sản phẩm
                                          if (optionValues.isNotEmpty)
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: optionValues.map<Widget>((
                                                opt,
                                              ) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "${opt['option']?['type'] ?? ''}: ${opt['value'] ?? ''}",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                "Số lượng: ${order['quantity'] ?? 0}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                "${order['price'] != null ? (double.parse(order['price'])).toInt() : 0}đ",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Thông tin trạng thái
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      currentStatus,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(currentStatus),
                                        color: _getStatusColor(currentStatus),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _getStatusText(currentStatus),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(
                                              currentStatus,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (order['delivery_person'] != null)
                                        Text(
                                          "Người giao: ${order['delivery_person']}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Thông tin khách hàng
                                const Text(
                                  "Thông tin khách hàng:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.person_outline, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Tên: ${recieveInfo['customer'] ?? 'N/A'}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "SĐT: ${recieveInfo['phone'] ?? 'N/A'}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Thông tin giao hàng
                                const Text(
                                  "Thông tin giao hàng:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Đến: ${to['address'] ?? ''}, ${to['ward'] ?? ''}, ${to['district'] ?? ''}, ${to['province'] ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Phí ship: ${order['delivery_charge'] != null ? (double.parse(order['delivery_charge'])).toInt() : 0}đ",
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            "Khoảng cách: ${order['distance'] != null ? (order['distance'] as num).toStringAsFixed(1) : 'N/A'} km",
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Nút cập nhật trạng thái
                                if (nextStatuses.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Cập nhật trạng thái:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: nextStatuses.map((status) {
                                          return OutlinedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text("Xác nhận"),
                                                  content: Text(
                                                    "Bạn có chắc muốn cập nhật trạng thái thành '${_getStatusText(status)}'?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text("Hủy"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _updateStatusDelivery(
                                                          order['id'],
                                                          status,
                                                        );
                                                      },
                                                      child: const Text(
                                                        "Xác nhận",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: _getStatusColor(status),
                                              ),
                                              backgroundColor: _getStatusColor(
                                                status,
                                              ).withOpacity(0.05),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                            ),
                                            child: Text(
                                              _getStatusText(status),
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    "Đơn hàng đã hoàn tất",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
