import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/features/checkout/screens/qr_generate_screen.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/screens/location_manager_screen.dart';
import 'package:frontend/features/location/services/location_service.dart';
import 'package:http/http.dart' as http;

class OrderFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  const OrderFormScreen({super.key, required this.orderItems});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  UserLocation? _selectedLocation;
  final TextEditingController _receivePhoneNumber = TextEditingController();
  List<Map<String, dynamic>> shippingRates = [];
  bool _isLoading = true;

  String _selectedPaymentMethod = "COD";

  @override
  void initState() {
    super.initState();
    _checkAndSelectLocation();

    for (var item in widget.orderItems) {
      item["delivery_method"] = "NORMAL";
    }
  }

  Future<void> _loadShippingRatesForCart(UserLocation location) async {
    try {
      final destinationRegion = location.province.administrativeRegion;

      for (var item in widget.orderItems) {
        final variant = item["variant"];
        final originRegion =
            variant["product"]["province"]["administrative_region"];

        if (originRegion == null || destinationRegion == null) continue;

        final uri = Uri.parse(
          "${ApiConfig.baseUrl}/shipping-route/find-by-regions/"
          "?origin=$originRegion&destination=$destinationRegion",
        );

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print("${variant['product']['name']}  $data");
          setState(() {
            item["shipping_rates"] = data["shipping_rates"];
            item["delivery_method"] = null;
          });
        } else {
          print("❌ Failed to load shipping for product ${variant["id"]}");
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("🔥 Error load shipping: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAndSelectLocation() async {
    if (_selectedLocation != null) return;

    final data = await LocationService.getLocation();

    if (data.isEmpty) {
      final selected = await Navigator.push<UserLocation>(
        context,
        MaterialPageRoute(
          builder: (_) => const LocationManagerScreen(isSelecting: true),
        ),
      );

      if (selected != null) {
        setState(() {
          _selectedLocation = selected;
        });
        await _loadShippingRatesForCart(selected);
      }
    } else {
      setState(() {
        _selectedLocation = data.first;
      });
      await _loadShippingRatesForCart(data.first);
    }
  }

  void _submitOrder() async {
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
    
    for (var item in widget.orderItems) {
      if (item["delivery_method"] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn phương thức giao hàng")),
        );
        return;
      }
    }

    final orderDetails = widget.orderItems.map((item) {
      return {
        "product": item["variant"]["id"],
        "quantity": item["quantity"],
        "distance": 10.5,
        "delivery_method": item["delivery_method"],
      };
    }).toList();

    final payload = {
      "province": _selectedLocation!.province.code,
      "district": _selectedLocation!.district.code,
      "ward": _selectedLocation!.ward.code,
      "address": _selectedLocation!.address,
      "receiver_phone_number": _receivePhoneNumber.text,
      "latitude": _selectedLocation!.latitude,
      "longitude": _selectedLocation!.longitude,
      "order_details": orderDetails,
      "payment_method": _selectedPaymentMethod, 
    };

    try {
      final res = await CheckoutService.addOrder(payload);


      if (res.containsKey("payUrl") && res["payUrl"] != null) {
        final payUrl = res["payUrl"];
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PaymentQrScreen(payUrl: payUrl, orderId: res["order_id"]),
          ),
        );
      }
      
      else if (res.containsKey("order_id")) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đặt hàng thành công!")));
        Navigator.pop(context, true);
      }
      
      else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đặt hàng thất bại: ${res.toString()}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Có lỗi xảy ra: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin đặt hàng")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Chọn địa chỉ giao hàng:"),
            ),
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LocationManagerScreen(isSelecting: true),
                  ),
                );

                if (result != null && result is UserLocation) {
                  setState(() {
                    _selectedLocation = result;
                  });
                  await _loadShippingRatesForCart(result);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocation != null
                            ? "${_selectedLocation!.address}, ${_selectedLocation!.ward.name}, ${_selectedLocation!.district.name}, ${_selectedLocation!.province.name}"
                            : "Chọn địa chỉ giao hàng",
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedLocation != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),


            TextField(
              controller: _receivePhoneNumber,
              decoration: const InputDecoration(
                labelText: "Số điện thoại nhận hàng",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),


            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Chọn phương thức thanh toán:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            RadioListTile<String>(
              title: const Text("Thanh toán khi nhận hàng (COD)"),
              value: "cod",
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text("Thanh toán qua MoMo"),
              value: "momo",
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),

            const SizedBox(height: 16),


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
                          Image.network(
                            (baseProduct['image']?.isNotEmpty ?? false)
                                ? baseProduct['image']
                                : "https://via.placeholder.com/100",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 12),
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
                                  items: (item["shipping_rates"] ?? [])
                                      .map<DropdownMenuItem<String>>((rate) {
                                        return DropdownMenuItem(
                                          value: rate["method"]
                                              .toString()
                                              .toUpperCase(),
                                          child: Text(
                                            "${rate['method']} - ${rate['price']}đ",
                                          ),
                                        );
                                      })
                                      .toList(),
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
