import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:frontend/features/product/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<List<ProductModel>> _productsFuture;
  final NumberFormat _formatter = NumberFormat("#,###", "vi_VN");
  Map<String, String> _filters = {};
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ProductService.getCategory();
      setState(() => _categories = cats);
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  void _fetchProducts() {
    setState(() {
      _productsFuture = ProductService.getProducts(params: _filters);
    });
  }

  void _onFilterChanged(Map<String, String> newFilters) {
    _filters = newFilters;
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Sản phẩm"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.7,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Chọn danh mục",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return ListTile(
                      title: Text(cat.type),
                      onTap: () {
                        // Gọi filter
                        _onFilterChanged({"category": cat.id.toString()});
                        Navigator.pop(context); // đóng drawer
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SearchAndFilterHeader(onFilterChanged: _onFilterChanged),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Không có sản phẩm"));
                }

                final products = snapshot.data!;
                return MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(productId: product.id),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: product.images.isNotEmpty
                                  ? Image.network(
                                      product.images[0].image,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    product.minPrice == product.maxPrice
                                        ? "${_formatter.format(product.minPrice)} đ"
                                        : "${_formatter.format(product.minPrice)} - ${_formatter.format(product.maxPrice)} đ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    product.soldQuantity == 0
                                        ? "Chưa có đơn hàng"
                                        : "Đã bán ${product.soldQuantity}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${product.ward}, ${product.province}",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Header tìm kiếm
class SearchAndFilterHeader extends StatefulWidget {
  final void Function(Map<String, String>) onFilterChanged;

  const SearchAndFilterHeader({super.key, required this.onFilterChanged});

  @override
  State<SearchAndFilterHeader> createState() => _SearchAndFilterHeaderState();
}

class _SearchAndFilterHeaderState extends State<SearchAndFilterHeader> {
  final TextEditingController _searchController = TextEditingController();

  void _applyFilters() {
    final filters = <String, String>{};
    if (_searchController.text.isNotEmpty) {
      filters["search"] = _searchController.text;
    }
    widget.onFilterChanged(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Tìm kiếm sản phẩm...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
        ],
      ),
    );
  }
}
