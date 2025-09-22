import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';
import 'package:frontend/features/product/models/product_detail_model.dart';
import 'package:frontend/features/user/screens/supplier_profile.dart';
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
  int _quantity = 1;
  List<Rate> rates = [];
  int _currentImageIndex = 0;
  Map<String, String?> selectedOptions = {}; 

  @override
  void initState() {
    super.initState();
    _productFuture = ProductService.getProductDetail(widget.productId);
    _fetchRate(widget.productId);
  }

  Future<void> _fetchRate(int id) async {
    try {
      final res = await ProductService.getRate(id); 
      setState(() {
        rates = res; 
      });
    } catch (e) {
      print("Lỗi khi lấy rate: $e");
    }
  }

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


  String getThumbnail(ProductVariant variant, ProductDetailModel product) {
    if (variant.product?.image.isNotEmpty == true) {
      return variant.product!.image;
    } else if (product.images.isNotEmpty) {
      return product.images[0].image;
    } else {
      return "https://via.placeholder.com/100";
    }
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
                  
                  if (product.images.isNotEmpty)
                    Column(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1.0,
                            enlargeCenterPage: false,
                            autoPlay: product.images.length > 1,
                            autoPlayInterval: const Duration(seconds: 4),
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                          ),
                          items: product.images.map((image) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: Image.network(
                                    image.image,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        if (product.images.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: product.images.asMap().entries.map((
                              entry,
                            ) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == entry.key
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),


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

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mô tả sản phẩm",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),


                        Text(
                          product.description.isNotEmpty
                              ? product.description
                              : "Chưa có mô tả ngắn",
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 12),


                        if (product.descriptions.isNotEmpty) ...[
                          const Text(
                            "Chi tiết:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: product.descriptions.map((d) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "• ",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "${d.title}: ${d.content}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(),
                  
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

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                            ),
                            Text(
                              "$_quantity",
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => _quantity++);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: (matchedVariant == null)
                                ? null
                                : () async {
                                    try {
                                      
                                      await CheckoutService.addToCart(
                                        matchedVariant.id,
                                        _quantity,
                                      );

                                      if (!mounted) return;
                                      
                                      final optionDesc = matchedVariant
                                          .optionValues
                                          .map(
                                            (ov) =>
                                                "${ov.option.type}: ${ov.value}",
                                          )
                                          .join(", ");


                                      final thumbnail = getThumbnail(
                                        matchedVariant,
                                        product,
                                      );


                                      showModalBottomSheet(
                                        context: context,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        builder: (_) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    thumbnail,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        optionDesc.isNotEmpty
                                                            ? optionDesc
                                                            : "Mặc định",
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        "Số lượng: $_quantity",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        "Giá: ${_formatter.format(matchedVariant.price)} đ",
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text("Lỗi: $e")),
                                      );
                                    }
                                  },
                            child: const Text(
                              "Thêm vào giỏ hàng",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: product.owner.avatar != null
                              ? NetworkImage(product.owner.avatar!)
                              : const NetworkImage(
                                  "https://via.placeholder.com/150",
                                ),
                        ),
                        const SizedBox(width: 12),


                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.owner.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Nhà cung cấp uy tín",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),


                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SupplierDetailScreen(
                                      userId: product.owner.id,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Xem shop"),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                
                              },
                              child: const Text("Chat"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Đánh giá sản phẩm",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (rates.isEmpty) const Text("Chưa có đánh giá nào"),
                        ...rates.map((r) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        r.ownerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            index < r.rate
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(r.content),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      "dd/MM/yyyy HH:mm",
                                    ).format(r.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
