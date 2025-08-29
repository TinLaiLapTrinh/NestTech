import 'package:flutter/material.dart';
import 'package:frontend/features/product/models/product_detail_model.dart';
import 'package:intl/intl.dart';

import '../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductDetailModel> _productFuture;
  final NumberFormat _formatter = NumberFormat("#,###", "vi_VN");

  Map<String, String?> selectedOptions = {}; // Lưu lựa chọn

  @override
  void initState() {
    super.initState();
    _productFuture = ProductService.getProductDetail(widget.productId);
  }

  /// Hàm tìm variant phù hợp với lựa chọn
  ProductVariant? findMatchingVariant(ProductDetailModel product) {
    for (var variant in product.variants) {
      bool ok = true;
      for (var opt in product.options) {
        final selectedValue = selectedOptions[opt.type];
        if (selectedValue != null &&
            !variant.optionValues.any((ov) => ov.value == selectedValue)) {
          ok = false;
          break;
        }
      }
      if (ok) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<ProductDetailModel>(
          future: _productFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Không tìm thấy sản phẩm"));
            }

            final product = snapshot.data!;
            final matchedVariant = findMatchingVariant(product);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh sản phẩm
                  if (product.images.isNotEmpty)
                    Image.network(
                      product.images[0].image,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.contain,
                    ),

                  // Tên + giá
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        matchedVariant != null
                            ? Text(
                                "${_formatter.format(matchedVariant.price)} đ",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              )
                            : Text(
                                "${_formatter.format(product.priceRange.min)} - ${_formatter.format(product.priceRange.max)} đ",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),

                        const SizedBox(height: 4),
                        Text("Đã bán: ${product.soldQuantity}"),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Tuỳ chọn
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.options.isNotEmpty) ...[
                          const Text(
                            "Tuỳ chọn:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.options.map((opt) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  children: opt.optionValues.map((val) {
                                    final isSelected =
                                        selectedOptions[opt.type] == val.value;
                                    return ChoiceChip(
                                      label: Text(val.value),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        setState(() {
                                          selectedOptions[opt.type] = val.value;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }),
                        ],

                        if (matchedVariant != null) ...[
                          Text("Kho: ${matchedVariant.stock}"),
                        ],
                      ],
                    ),
                  ),

                  const Divider(),

                  // Gian hàng + vị trí
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gian hàng",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Chủ shop: ${product.owner.name} (ID: ${product.owner.id})",
                        ),
                        Text(
                          "Khu vực: ${product.location.province ?? "-"}, ${product.location.ward ?? "-"}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
