import 'package:flutter/material.dart';
import 'package:frontend/features/product/models/product_model.dart';
import 'package:frontend/features/product/services/product_service.dart';
import 'package:frontend/features/user/models/user_model.dart';
import 'package:frontend/features/user/services/user_service.dart';

class SupplierDetailScreen extends StatefulWidget {
  final int userId;

  const SupplierDetailScreen({super.key, required this.userId});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  late Future<UserModel> _futureUser;
  late Future<List<ProductModel>> _futureProducts;
  bool? _isFollowing;

  @override
  void initState() {
    super.initState();
    _futureUser = UserService.getDetailUser(widget.userId);
    _futureProducts = ProductService.getShopProducts(widget.userId);
    _loadFollowingStatus();
  }

  Future<void> _loadFollowingStatus() async {
    try {
      final result = await UserService.isFollowing(widget.userId);
      setState(() {
        _isFollowing = result;
      });
    } catch (e) {
      debugPrint("Error check following: $e");
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowing == null) return;

    try {
      if (_isFollowing!) {
        await UserService.unFollow(widget.userId);
        setState(() => _isFollowing = false);
      } else {
        await UserService.follow(widget.userId);
        setState(() => _isFollowing = true);
      }
    } catch (e) {
      debugPrint("Follow action failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:  Text("Lỗi khi thực hiện thao tác ")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin nhà phân phối")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<UserModel>(
          future: _futureUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Không tìm thấy thông tin"));
            }

            final supplier = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage:
                          (supplier.avatar != null &&
                              supplier.avatar!.isNotEmpty)
                          ? NetworkImage(supplier.avatar!)
                          : null,
                      child:
                          (supplier.avatar == null || supplier.avatar!.isEmpty)
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),


                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${supplier.firstName} ${supplier.lastName}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (supplier.isVerified ?? false) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "@${supplier.username}",
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Email: ${supplier.email}",
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Địa chỉ: ${supplier.address ?? "Chưa có"}",
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text("Người theo dõi: ${supplier.followCount ?? 0}"),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),


                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: ElevatedButton(
                        onPressed: _isFollowing == null ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _isFollowing == true ? "Đang theo dõi" : "Theo dõi",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Sản phẩm của shop",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                FutureBuilder<List<ProductModel>>(
                  future: _futureProducts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Lỗi khi tải sản phẩm: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("Shop chưa có sản phẩm nào");
                    }

                    final products = snapshot.data!;

                    return SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      product.images.isNotEmpty
                                          ? product.images.first.image
                                          : "",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${product.minPrice} đ",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
