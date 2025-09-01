import 'package:flutter/material.dart';
import 'package:frontend/features/product/models/product_detail_model.dart';
import 'package:frontend/features/product/services/product_service.dart';

class VariantListPage extends StatefulWidget {
  final int productId;

  const VariantListPage({super.key, required this.productId});

  @override
  State<VariantListPage> createState() => _VariantListPageState();
}

class _VariantListPageState extends State<VariantListPage> {
  List<ProductVariant> variants = [];
  List<Option> options = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final variantData = await ProductService.getVariants(widget.productId);
      final optionData = await ProductService.getOption(widget.productId);

      if (!mounted) return;

      setState(() {
        variants = variantData;
        options = optionData;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
    }
  }

  void _showEditVariantDialog(ProductVariant variant) {
    final priceController = TextEditingController(
      text: variant.price.toString(),
    );
    final stockController = TextEditingController(
      text: variant.stock.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chỉnh sửa biến thể"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Giá"),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Tồn kho"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = int.tryParse(priceController.text) ?? 0;
                final stock = int.tryParse(stockController.text) ?? 0;
                
                try {
                  await ProductService.updateVariant(
                    widget.productId, // dùng productId từ widget
                    variant.id,
                    stock,
                    price,
                  );

                  // Cập nhật local state luôn
                  setState(() {
                    variant.price = price.toDouble();
                    variant.stock = stock;
                  });

                  Navigator.pop(context); // đóng popup
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cập nhật thành công")),
                  );
                } catch (e) {
                  print("lỗi cập nhật: $e");
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách biến thể")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : variants.isEmpty
          ? const Center(child: Text("Chưa có biến thể nào"))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text("ID")),
                    ...options.map((o) => DataColumn(label: Text(o.type))),
                    const DataColumn(label: Text("Giá")),
                    const DataColumn(label: Text("Tồn kho")),
                    const DataColumn(label: Text("Hành động")),
                  ],
                  rows: variants.map((variant) {
                    return DataRow(
                      cells: [
                        DataCell(Text(variant.id.toString())),
                        ...options.map((o) {
                          final match = variant.optionValues.firstWhere(
                            (ov) => ov.option.type == o.type,
                            orElse: () => OptionValue(
                              id: 0,
                              value: "-",
                              option: OptionType(type: o.type),
                            ),
                          );
                          return DataCell(Text(match.value));
                        }),
                        DataCell(Text(variant.price.toString())),
                        DataCell(Text(variant.stock.toString())),
                        DataCell(
                          ElevatedButton(
                            onPressed: () => _showEditVariantDialog(variant),
                            child: const Text("Chỉnh sửa"),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
