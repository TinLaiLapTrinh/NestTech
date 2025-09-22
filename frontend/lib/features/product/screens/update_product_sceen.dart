import 'package:carousel_slider/carousel_slider.dart';
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

  Future<void> _updateDescriptions(
    List<Description> newList,
    int productId,
  ) async {
    try {
      final updated = await ProductService.updateDescriptions(
        newList,
        productId,
      );
      if (updated == true) {
        setState(() {
          _loadDetail();
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi tải chi tiết: $e");
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
      appBar: AppBar(title: const Text("Chi tiết sản phẩm")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            if (p.images.isNotEmpty) ...[
              CarouselSlider(
                options: CarouselOptions(
                  height: 220,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: true,
                  autoPlay: true,
                ),
                items: p.images.map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      img.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],


            Text(
              p.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Trạng thái: ${p.status}"),
            const Divider(),


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


            Text("Danh mục: ${p.category}"),
            Text("Địa chỉ: ${p.location.ward}, ${p.location.province}"),
            const Divider(),


            const Text(
              "Mô tả sản phẩm:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              p.description.isNotEmpty ? p.description : "Chưa có mô tả ngắn",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),


            const Text(
              "Chi tiết:",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 6),
            if (p.descriptions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: p.descriptions.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            "${d.title}: ${d.content}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () async {
                            final edited = await showDialog<Description>(
                              context: context,
                              builder: (_) => _EditDescriptionDialog(item: d),
                            );
                            if (edited != null) {
                              final newList = [...p.descriptions];
                              final index = newList.indexOf(d);
                              newList[index] = edited;
                              await _updateDescriptions(newList, p.id);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final newList = [...p.descriptions]..remove(d);
                            await _updateDescriptions(newList, p.id);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                final newDesc = await showDialog<Description>(
                  context: context,
                  builder: (_) => const _EditDescriptionDialog(),
                );
                if (newDesc != null) {
                  final newList = [...p.descriptions, newDesc];
                  await _updateDescriptions(newList, p.id);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Thêm chi tiết"),
            ),
            const Divider(),


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
                      "- ${o.type}: ${o.optionValues.map((v) => v.value).join(", ")}",
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
                if (newOption != null) _loadDetail();
              },
              icon: const Icon(Icons.add),
              label: const Text("Thêm thuộc tính"),
            ),


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
                    "Kho: ${v.stock} | Thuộc tính: " +
                        v.optionValues.map((ov) => ov.value).join(', '),
                  ),
                ),
              ),
              const Divider(),
            ],


            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VariantListPage(productId: widget.productId),
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
                      
                    },
                    child: const Text("Xóa / Ẩn"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final variants = await ProductService.generateVariants(
                          p.id,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã tạo ${variants.length} variant"),
                          ),
                        );
                        _loadDetail();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi khi tạo variant: $e")),
                        );
                      }
                    },
                    child: const Text("Biến thể"),
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

class _EditDescriptionDialog extends StatefulWidget {
  final Description? item;
  const _EditDescriptionDialog({this.item});

  @override
  State<_EditDescriptionDialog> createState() => _EditDescriptionDialogState();
}

class _EditDescriptionDialogState extends State<_EditDescriptionDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _titleCtrl.text = widget.item!.title;
      _contentCtrl.text = widget.item!.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? "Thêm chi tiết" : "Chỉnh sửa chi tiết"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: "Tiêu đề"),
          ),
          TextField(
            controller: _contentCtrl,
            decoration: const InputDecoration(labelText: "Nội dung"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.isNotEmpty && _contentCtrl.text.isNotEmpty) {
              Navigator.pop(
                context,
                Description(
                  id: widget.item?.id ?? 0, 
                  title: _titleCtrl.text,
                  content: _contentCtrl.text,
                ),
              );
            }
          },
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
