import 'package:flutter/material.dart';

class VariantFormPage extends StatefulWidget {
  final List<Map<String, dynamic>> optionValues;
  final Map<String, dynamic>? existing;

  const VariantFormPage({super.key, required this.optionValues, this.existing});

  @override
  State<VariantFormPage> createState() => _VariantFormPageState();
}

class _VariantFormPageState extends State<VariantFormPage> {
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _skuController.text = widget.existing!['sku'] ?? '';
      _priceController.text = widget.existing!['price'] ?? '';
      _stockController.text = widget.existing!['stock'] ?? '';
    }
  }

  void _save() {
    final variant = {
      "sku": _skuController.text.trim(),
      "price": _priceController.text.trim(),
      "stock": _stockController.text.trim(),
      "option_values": widget.optionValues.map((v) => v['id']).toList(),
    };

    Navigator.pop(context, variant);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.optionValues.map((c) => c['name']).join(" - ");

    return Scaffold(
      appBar: AppBar(title: Text("Setup: $label")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Biến thể: $label", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: "SKU"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Giá"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: "Tồn kho"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text("Lưu"))
          ],
        ),
      ),
    );
  }
}
