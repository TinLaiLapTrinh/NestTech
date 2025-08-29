import 'package:flutter/material.dart';
import 'package:frontend/features/product/models/product_detail_model.dart';
import 'package:frontend/features/product/screens/option_create_screen.dart';
import 'package:frontend/features/product/screens/product_variant_list_screen.dart';

import '../services/product_service.dart';

class MyProductDetailScreen extends StatefulWidget {
  final int productId;

  const MyProductDetailScreen({super.key, required this.productId});

  @override
  State<MyProductDetailScreen> createState() => _MyProductDetailScreenState();
}

class _MyProductDetailScreenState extends State<MyProductDetailScreen> {
  ProductDetailModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await ProductService.getProductDetail(widget.productId);
      setState(() {
        _product = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải chi tiết: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy sản phẩm")),
      );
    }

    final p = _product!;

    return Scaffold(
      appBar: AppBar(title: Text("Chi tiết sản phẩm")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh chính
            if (p.images.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView(
                  children: p.images
                      .map(
                        (img) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(img.image, fit: BoxFit.cover),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 12),

            // Tên + trạng thái
            Text(
              p.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Trạng thái: ${p.status}"),
            const Divider(),

            // Giá
            Text(
              "Giá: ${p.priceRange.min} - ${p.priceRange.max} đ",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Đã bán: ${p.soldQuantity}"),
            const Divider(),

            // Danh mục, địa chỉ
            Text("Danh mục: ${p.category}"),
            Text("Địa chỉ: ${p.location.ward}, ${p.location.province}"),
            const Divider(),

            // Mô tả
            const Text(
              "Mô tả sản phẩm:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(p.description),
            const Divider(),

            // Option
            if (p.options.isNotEmpty) ...[
              const Text(
                "Thuộc tính:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...p.options.map(
                (o) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "- ${o.type}: " +
                          o.optionValues.map((v) => v.value).join(", "),
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
            ElevatedButton.icon(
              onPressed: () async {
                final newOption = await showDialog(
                  context: context,
                  builder: (_) => ProductOptionSetup(productId: p.id),
                );
                if (newOption != null) {
                  _loadDetail(); // reload lại sau khi thêm option
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Thêm thuộc tính"),
            ),
            // Variants
            if (p.variants.isNotEmpty) ...[
              const Text(
                "Biến thể:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...p.variants.map(
                (v) => ListTile(
                  leading: const Icon(Icons.widgets),
                  title: Text("Giá: ${v.price} đ"),
                  subtitle: Text(
                    "Kho: ${v.stock} | Thuộc tính: ${v.optionValues.map((ov) => ov.value).join(', ')}",
                  ),
                ),
              ),
              const Divider(),
            ],

            // Action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VariantListPage(
                            productId: widget.productId
                          ),
                        ),
                      );
                    },
                    child: const Text("Chỉnh sửa"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Ẩn / Xóa sản phẩm
                    },
                    child: const Text("Xóa / Ẩn"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
