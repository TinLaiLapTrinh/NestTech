import 'package:flutter/material.dart';
import 'package:frontend/features/product/services/product_service.dart';

class VariantListPage extends StatefulWidget {
  final int productId;

  const VariantListPage({super.key, required this.productId});

  @override
  State<VariantListPage> createState() => _VariantListPageState();
}

class _VariantListPageState extends State<VariantListPage> {
  List<Map<String, dynamic>> variants = [];
  List<Map<String, dynamic>> options = [];
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

      setState(() {
        variants = List<Map<String, dynamic>>.from(variantData);
        options = List<Map<String, dynamic>>.from(optionData);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
    }
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
                        ...options.map((o) => DataColumn(label: Text(o["type"]))),
                        const DataColumn(label: Text("Giá")),
                        const DataColumn(label: Text("Tồn kho")),
                        const DataColumn(label: Text("Hành động")),
                      ],
                      rows: variants.map((variant) {
                        final optionValues = variant["option_values"] as List;

                        return DataRow(
                          cells: [
                            DataCell(Text(variant["id"].toString())),
                            ...options.map((o) {
                              final match = optionValues.firstWhere(
                                (ov) => ov["option"]["type"] == o["type"],
                                orElse: () => null,
                              );
                              return DataCell(
                                Text(match != null ? match["value"].toString() : "-"),
                              );
                            }),
                            DataCell(Text(variant["price"].toString())),
                            DataCell(Text(variant["stock"].toString())),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/edit-variant",
                                    arguments: {
                                      "variant": variant,
                                      "options": options,
                                    },
                                  );
                                },
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
