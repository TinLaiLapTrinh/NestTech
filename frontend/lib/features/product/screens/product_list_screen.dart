import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
  double? _minPrice;
  double? _maxPrice;
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

      final params = {..._filters, "page": _currentPage.toString()};

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
                  "Bộ lọc sản phẩm",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Danh mục",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return ListTile(
                      title: Text(cat.type),
                      onTap: () {
                        _onFilterChanged({
                          "category": cat.id.toString(),
                          "search": _filters["search"] ?? "",
                          "min_price": _minPrice?.toString() ?? "",
                          "max_price": _maxPrice?.toString() ?? "",
                          "min_rate": _filters["min_rate"] ?? "",
                          "max_rate": _filters["max_rate"] ?? "",
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text("Lọc theo giá"),
                onTap: () async {
                  final range = await showDialog<Map<String, double>>(
                    context: context,
                    builder: (context) {
                      double minTemp = _minPrice ?? 0;
                      double maxTemp = _maxPrice ?? 10000000;
                      return AlertDialog(
                        title: const Text("Chọn khoảng giá"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: "Giá thấp nhất",
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  minTemp = double.tryParse(v) ?? 0,
                            ),
                            TextField(
                              decoration: const InputDecoration(
                                labelText: "Giá cao nhất",
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  maxTemp = double.tryParse(v) ?? 0,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Hủy"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, {
                              "min_price": minTemp,
                              "max_price": maxTemp,
                            }),
                            child: const Text("Áp dụng"),
                          ),
                        ],
                      );
                    },
                  );

                  if (range != null) {
                    setState(() {
                      _minPrice = range["min_price"];
                      _maxPrice = range["max_price"];
                    });
                    _onFilterChanged({
                      "category": _filters["category"] ?? "",
                      "search": _filters["search"] ?? "",
                      "min_price": _minPrice.toString(),
                      "max_price": _maxPrice.toString(),
                      "min_rate": _filters["min_rate"] ?? "",
                      "max_rate": _filters["max_rate"] ?? "",
                    });
                    Navigator.pop(context);
                  }
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.star_rate),
                title: const Text("Lọc theo đánh giá"),
                onTap: () async {
                  double minTemp = _filters["min_rate"] != null
                      ? double.tryParse(_filters["min_rate"]!) ?? 0
                      : 0;
                  double maxTemp = _filters["max_rate"] != null
                      ? double.tryParse(_filters["max_rate"]!) ?? 5
                      : 5;

                  final result = await showDialog<Map<String, double>>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Chọn khoảng sao"),
                        content: StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Sao tối thiểu:"),
                                RatingBar.builder(
                                  initialRating: minTemp,
                                  minRating: 0,
                                  maxRating: 5,
                                  allowHalfRating: true,
                                  itemSize: 30,
                                  itemCount: 5,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {
                                    setState(() => minTemp = rating);
                                  },
                                ),
                                const SizedBox(height: 12),
                                Text("Sao tối đa:"),
                                RatingBar.builder(
                                  initialRating: maxTemp,
                                  minRating: 0,
                                  maxRating: 5,
                                  allowHalfRating: true,
                                  itemSize: 30,
                                  itemCount: 5,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {
                                    setState(() => maxTemp = rating);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Hủy"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, {
                              "min_rate": minTemp,
                              "max_rate": maxTemp,
                            }),
                            child: const Text("Áp dụng"),
                          ),
                        ],
                      );
                    },
                  );

                  if (result != null) {
                    _onFilterChanged({
                      "category": _filters["category"] ?? "",
                      "search": _filters["search"] ?? "",
                      "min_price": _filters["min_price"] ?? "",
                      "max_price": _filters["max_price"] ?? "",
                      "min_rate": result["min_rate"].toString(),
                      "max_rate": result["max_rate"].toString(),
                    });
                    Navigator.pop(context);
                  }
                },
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
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else if (!_hasMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  "Đã tải hết sản phẩm",
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
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${product.ward}, ${product.province}",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: product.rate.avg,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 16.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "(${product.rate.quantity})",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: "Xoá bộ lọc",
            onPressed: () {
              _searchController.clear();
              widget.onFilterChanged({});
            },
          ),
        ],
      ),
    );
  }
}
