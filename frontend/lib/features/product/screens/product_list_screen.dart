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
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _formatter = NumberFormat("#,###", "vi_VN");

  Map<String, String> _filters = {};
  List<ProductModel> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _scrollThrottled = false;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchProducts(initial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          !_scrollThrottled) {
        _scrollThrottled = true;
        _fetchProducts().then((_) => _scrollThrottled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ProductService.getCategory();
      if (!mounted) return;
      setState(() => _categories = cats);
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  Future<void> _fetchProducts({bool initial = false}) async {
    if (_isLoading || !_hasMore) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (initial) {
        _currentPage = 1;
        _products.clear();
        _hasMore = true;
      }

      final params = {
        ..._filters,
        "page": _currentPage.toString(),
      };

      final newProducts = await ProductService.getProducts(params: params);
      if (!mounted) return;

      setState(() {
        if (newProducts.isEmpty) {
          _hasMore = false;
        } else {
          _products.addAll(newProducts);
          _currentPage++;
        }
      });
    } catch (e) {
      debugPrint("Error loading products: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(Map<String, String> newFilters) {
    _filters = newFilters;
    _fetchProducts(initial: true);
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
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
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
                        _onFilterChanged({"category": cat.id.toString()});
                        Navigator.pop(context);
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
            child: RefreshIndicator(
              onRefresh: () => _fetchProducts(initial: true),
              child: _products.isEmpty && !_isLoading
                  ? const Center(child: Text("Không có sản phẩm"))
                  : MasonryGridView.count(
                      controller: _scrollController,
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: _products.length + 1,
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          if (_isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          } else if (!_hasMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  "🎉 Đã tải hết sản phẩm",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox();
                          }
                        }
                        return _buildProductCard(_products[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(productId: product.id)),
        );
      },
      child: Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: product.images.isNotEmpty
                  ? Image.network(product.images[0].image, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 40),
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
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.minPrice == product.maxPrice
                        ? "${_formatter.format(product.minPrice)} đ"
                        : "${_formatter.format(product.minPrice)} - ${_formatter.format(product.maxPrice)} đ",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.soldQuantity == 0
                        ? "Chưa có đơn hàng"
                        : "Đã bán ${product.soldQuantity}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${product.ward}, ${product.province}",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
