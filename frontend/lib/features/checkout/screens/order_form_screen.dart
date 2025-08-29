import 'package:flutter/material.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/services/location_service.dart';

class OrderFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems; // từ MyCartItemsScreen

  const OrderFormScreen({super.key, required this.orderItems});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  List<UserLocation> _userLocations = [];
  UserLocation? _selectedLocation;
  final TextEditingController _receivePhoneNumber = TextEditingController();
  bool _isLoading = true;

  final List<String> deliveryMethods = ["FAST", "NORMAL"];

  @override
  void initState() {
    super.initState();
    _loadLocations();
    // Gán mặc định phương thức giao hàng cho mỗi item
    for (var item in widget.orderItems) {
      item["delivery_method"] = "NORMAL";
    }
  }

  Future<void> _loadLocations() async {
    final data = await LocationService.getLocation();
    setState(() {
      _userLocations = data;
      _isLoading = false;
      if (data.isNotEmpty) {
        _selectedLocation = data.first;
      }
    });
  }

  void _submitOrder() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn địa chỉ giao hàng")),
      );
      return;
    }
    if (_receivePhoneNumber.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập số điện thoại")),
      );
      return;
    }

    // Build order_details từ các items
    final orderDetails = widget.orderItems.map((item) {
      return {
        "product": item["variant"]["id"], // id của variant
        "quantity": item["quantity"],
        "distance": 10.5, // TODO: tính từ location service
        "delivery_method": item["delivery_method"],
      };
    }).toList();

    // Build payload tổng
    final payload = {
      "province": _selectedLocation!.provinceCode,
      "ward": _selectedLocation!.wardCode,
      "address": _selectedLocation!.address,
      "receiver_phone_number": _receivePhoneNumber.text,
      "latitude": _selectedLocation!.latitude,
      "longitude": _selectedLocation!.longitude,
      "order_details": orderDetails,
    };

    debugPrint("📦 Order payload: $payload");

    // TODO: gọi CheckoutService.createOrder(payload)
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin đặt hàng")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Địa chỉ giao hàng
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Chọn địa chỉ giao hàng:"),
            ),
            DropdownButton<UserLocation>(
              isExpanded: true,
              value: _selectedLocation,
              items: _userLocations.map((loc) {
                return DropdownMenuItem(
                  value: loc,
                  child: Text("${loc.address} (${loc.provinceCode}-${loc.wardCode})"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedLocation = val;
                });
              },
            ),
            const SizedBox(height: 16),

            // Số điện thoại
            TextField(
              controller: _receivePhoneNumber,
              decoration: const InputDecoration(
                labelText: "Số điện thoại nhận hàng",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Danh sách sản phẩm trong order
            Expanded(
              child: ListView.builder(
                itemCount: widget.orderItems.length,
                itemBuilder: (context, index) {
                  final item = widget.orderItems[index];
                  final variant = item["variant"];
                  final baseProduct = variant["product"];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hình ảnh
                          Image.network(
                            (baseProduct['image']?.isNotEmpty ?? false)
                                ? baseProduct['image']
                                : "https://via.placeholder.com/100",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 12),

                          // Thông tin sản phẩm
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  baseProduct["name"] ?? "Không tên",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text("Số lượng: ${item["quantity"]}"),
                                Text("Giá: ${variant["price"]} đ"),
                                const SizedBox(height: 8),

                                DropdownButton<String>(
                                  isExpanded: true,
                                  value: item["delivery_method"],
                                  items: deliveryMethods.map((method) {
                                    return DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      item["delivery_method"] = val;
                                    });
                                  },
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
            ),

            // Nút xác nhận
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Xác nhận đặt hàng"),
              onPressed: _submitOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
