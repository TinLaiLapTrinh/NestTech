import 'package:flutter/material.dart';
import 'package:frontend/features/product/screens/add_new_product_form.dart';
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
  List<ProductModel> _deletedProducts = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _showDeleted = false;
  String _searchQuery = '';

  int _currentPage = 1;
  bool _hasNextPage = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts(reset: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasNextPage &&
          !_isLoading) {
        _loadProducts();
      }
    });
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasNextPage = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final data = await ProductService.getMyProduct(page: _currentPage);
      final deletedData =
          await ProductService.getMyProductDeteted();

      setState(() {
        if (reset) {
          _myProducts = data;
          _deletedProducts = deletedData;
        } else {
          _myProducts.addAll(data);
          _deletedProducts.addAll(deletedData);
        }

        if (data.isEmpty) {
          _hasNextPage = false;
        } else {
          _currentPage++;
        }
      });
    } catch (e) {
      debugPrint("❌ Lỗi tải sản phẩm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải sản phẩm: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  List<ProductModel> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _showDeleted ? _deletedProducts : _myProducts;
    }

    final listToSearch = _showDeleted ? _deletedProducts : _myProducts;
    return listToSearch
        .where((product) =>
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(_showDeleted ? "Sản phẩm đã xoá" : "Quản lý sản phẩm"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_showDeleted ? Icons.list : Icons.delete_outline),
            onPressed: () {
              setState(() {
                _showDeleted = !_showDeleted;
                _searchController.clear();
                _searchQuery = '';
              });
            },
            tooltip: _showDeleted
                ? "Xem sản phẩm đang bán"
                : "Xem sản phẩm đã xoá",
          ),
        ],
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm kiếm sản phẩm...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),


          if (!_showDeleted && _myProducts.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    _myProducts.length.toString(),
                    "Tổng SP",
                    Colors.blue,
                  ),
                  _buildStatItem(
                    _myProducts
                        .where((p) => p.status == "approved")
                        .length
                        .toString(),
                    "Đang bán",
                    Colors.green,
                  ),
                  _buildStatItem(
                    _myProducts
                        .where((p) => p.status != "approved")
                        .length
                        .toString(),
                    "Tạm ẩn",
                    Colors.orange,
                  ),
                ],
              ),
            ),


          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadProducts(reset: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount:
                              displayList.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == displayList.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final p = displayList[index];
                            final firstImage = p.images.isNotEmpty
                                ? p.images[0].image
                                : null;

                            return _buildProductCard(p, firstImage);
                          },
                        ),
                      ),
          ),
        ],
      ),


      floatingActionButton: !_showDeleted
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateProductScreen(),
                  ),
                );
                if (created == true) {
                  _loadProducts(reset: true);
                }
              },
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showDeleted ? Icons.delete_forever : Icons.inventory_2,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "Không tìm thấy sản phẩm phù hợp"
                : _showDeleted
                    ? "Chưa có sản phẩm nào bị xoá"
                    : "Bạn chưa có sản phẩm nào",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text("Xóa tìm kiếm"),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel p, String? firstImage) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyProductDetailScreen(productId: p.id),
            ),
          ).then((value) => _loadProducts(reset: true));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: firstImage != null
                    ? Image.network(
                        firstImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),


              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),


                    Text(
                      "₫${p.minPrice.toStringAsFixed(0).replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]}.',
                          )}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),


                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sell,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "Đã bán: ${p.soldQuantity}",
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        _buildStatusChip(p.status),
                      ],
                    ),
                  ],
                ),
              ),


              if (!_showDeleted)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MyProductDetailScreen(productId: p.id),
                          ),
                        ).then((value) => _loadProducts(reset: true));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(p),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isApproved = status == "approved";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isApproved ? Colors.green : Colors.orange,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.pause_circle,
            size: 12,
            color: isApproved ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isApproved ? "Đang bán" : "Tạm ẩn",
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: isApproved ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported,
          size: 30, color: Colors.grey),
    );
  }

  Future<void> _showDeleteConfirmation(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa sản phẩm"),
        content: Text("Bạn có chắc chắn muốn xóa '${product.name}' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ProductService.deleteProduct(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã xóa sản phẩm '${product.name}'")),
        );
        _loadProducts(reset: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi xóa sản phẩm: $e")),
        );
      }
    }
  }
}
