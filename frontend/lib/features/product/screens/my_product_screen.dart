import 'package:flutter/material.dart';
import 'package:frontend/features/product/screens/update_product_sceen.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class MyProductListScreen extends StatefulWidget {
  const MyProductListScreen({super.key});

  @override
  State<MyProductListScreen> createState() => _MyProductListScreenState();
}

class _MyProductListScreenState extends State<MyProductListScreen> {
  List<ProductModel> _myProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await ProductService.getMyProduct();
    setState(() {
      _myProducts = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý sản phẩm")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myProducts.isEmpty
          ? const Center(child: Text("Bạn chưa có sản phẩm nào"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _myProducts.length,
              itemBuilder: (context, index) {
                final p = _myProducts[index];
                final firstImage = p.images.isNotEmpty
                    ? p.images[0].image
                    : null;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh sản phẩm
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: firstImage != null
                              ? Image.network(
                                  firstImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Thông tin sản phẩm
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "₫${p.minPrice.toStringAsFixed(0)} - ₫${p.maxPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.sell,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text("Đã bán: ${p.soldQuantity}"),
                                  const SizedBox(width: 12),
                                  Icon(
                                    p.status == "active"
                                        ? Icons.check_circle
                                        : Icons.pause_circle,
                                    color: p.status == "active"
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.status == "active"
                                        ? "Đang bán"
                                        : "Tạm ẩn",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p.status == "active"
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Nút thao tác
                        // Thay phần nút thao tác
                        Column(
                          children: [
                            // Nút Edit - chuyển sang màn UpdateProductScreen
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MyProductDetailScreen(productId: p.id),
                                  ),
                                ).then((value) {
                                  // Sau khi update xong quay lại thì reload danh sách
                                  _loadProducts();
                                });
                              },
                            ),

                            // Nút Delete - confirm trước khi xóa
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Xóa sản phẩm"),
                                    content: Text(
                                      "Bạn có chắc chắn muốn xóa '${p.name}' không?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Hủy"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          "Xóa",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  // Gọi service xóa sản phẩm
                                  await ProductService.deleteProduct(p.id);
                                  _loadProducts(); // Reload lại danh sách
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
