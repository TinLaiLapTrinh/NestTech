import 'package:flutter/material.dart';
import 'package:frontend/features/product/models/product_option_model.dart';
import 'package:frontend/features/product/services/product_service.dart';


class ProductOptionSetup extends StatefulWidget {
  final int productId;
  const ProductOptionSetup({super.key, required this.productId});

  @override
  State<ProductOptionSetup> createState() => _ProductOptionSetupState();
}

class _ProductOptionSetupState extends State<ProductOptionSetup> {
  final _typeController = TextEditingController();
  final List<TextEditingController> _valueControllers = [TextEditingController()];
  bool _imageRequire = false;
  bool _loading = false;

  void _addValueFieldIfNeeded(int index) {
    if (_valueControllers[index].text.isNotEmpty &&
        index == _valueControllers.length - 1) {
      setState(() {
        _valueControllers.add(TextEditingController());
      });
    }
  }

  Future<void> _submit() async {
    final type = _typeController.text.trim();
    if (type.isEmpty) return;

    setState(() => _loading = true);

    try {
      final values = _valueControllers
          .map((c) => c.text.trim())
          .where((v) => v.isNotEmpty)
          .toList();

      final option = OptionModel(
        type: type,
        values: values,
        imageRequire: _imageRequire ? 1 : 0,
      );

      await ProductService.productOptionSetup(widget.productId, [option]);

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi thêm option: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thêm thuộc tính"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: "Tên thuộc tính (VD: Màn hình)"),
            ),
            const SizedBox(height: 8),
            const Text("Giá trị:", style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              children: List.generate(_valueControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: _valueControllers[index],
                    decoration: InputDecoration(
                      labelText: "Giá trị ${index + 1}",
                    ),
                    onChanged: (_) => _addValueFieldIfNeeded(index),
                  ),
                );
              }),
            ),
            Row(
              children: [
                const Text("Yêu cầu hình ảnh"),
                Switch(
                  value: _imageRequire,
                  onChanged: (v) => setState(() => _imageRequire = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Lưu"),
        ),
      ],
    );
  }
}
