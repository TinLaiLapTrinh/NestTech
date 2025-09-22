import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/services/location_service.dart';
import 'package:frontend/features/product/models/product_model.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_register_model.dart';
import '../services/product_service.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final minPriceCtrl = TextEditingController();
  final maxPriceCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  // Location
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;

  // Category
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;

  // Descriptions động
  List<DescriptionItem> descriptions = [];

  // Images
  List<File> selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProvinces();
  }

  // ========== Descriptions ==========
 void _addDescription() {
  setState(() {
    descriptions.add(DescriptionItem(
      title: "Thông tin sản phẩm", // Giá trị mặc định thay vì rỗng
      content: "Mô tả chi tiết",
    ));
  });
}


  void _removeDescription(int index) {
    setState(() {
      descriptions.removeAt(index);
    });
  }

  Widget _buildDescriptionInputs() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Thông tin chi tiết *",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addDescription,
          ),
        ],
      ),
      
      if (descriptions.isEmpty)
        const Text(
          "Vui lòng thêm ít nhất 1 thông tin chi tiết",
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      
      ...descriptions.asMap().entries.map((entry) {
        final index = entry.key;
        final desc = entry.value;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextFormField(
                  initialValue: desc.title,
                  decoration: InputDecoration(
                    labelText: "Tiêu đề *",
                    errorText: desc.title.isEmpty ? "Vui lòng nhập tiêu đề" : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      descriptions[index] = desc.copyWith(title: val);
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: desc.content,
                  decoration: InputDecoration(
                    labelText: "Nội dung *",
                    errorText: desc.content.isEmpty ? "Vui lòng nhập nội dung" : null,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (val) {
                    setState(() {
                      descriptions[index] = desc.copyWith(content: val);
                    });
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeDescription(index),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}
  // ========== Load dữ liệu ==========
  Future<void> _loadCategories() async {
    try {
      final cats = await ProductService.getCategory();
      setState(() => _categories = cats);
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final provs = await LocationService.getProvinces();
      setState(() => _provinces = provs);
    } catch (e) {
      debugPrint("Error loading provinces: $e");
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    try {
      final dists = await LocationService.getDistricts(provinceCode);
      setState(() => _districts = dists);
    } catch (e) {
      debugPrint("Error loading districts: $e");
    }
  }

  Future<void> _loadWards(String districtCode) async {
    try {
      final wards = await LocationService.getWards(districtCode);
      setState(() => _wards = wards);
    } catch (e) {
      debugPrint("Error loading wards: $e");
    }
  }

  // ========== Location Selector ==========
  Widget _buildProvinceSelector() {
    return _buildSelector(
      label: "Tỉnh/Thành phố",
      value: _selectedProvince?.fullName,
      options: _provinces.map(
        (p) => MapEntry(p.fullName, () async {
          Navigator.pop(context);
          setState(() {
            _selectedProvince = p;
            _selectedDistrict = null;
            _selectedWard = null;
            _districts = [];
            _wards = [];
          });
          await _loadDistricts(p.code);
        }),
      ),
    );
  }

  Widget _buildDistrictSelector() {
    if (_districts.isEmpty) return const SizedBox.shrink();
    return _buildSelector(
      label: "Quận/Huyện",
      value: _selectedDistrict?.fullName,
      options: _districts.map(
        (d) => MapEntry(d.fullName, () async {
          Navigator.pop(context);
          setState(() {
            _selectedDistrict = d;
            _selectedWard = null;
            _wards = [];
          });
          await _loadWards(d.code);
        }),
      ),
    );
  }

  Widget _buildWardSelector() {
    if (_wards.isEmpty) return const SizedBox.shrink();
    return _buildSelector(
      label: "Phường/Xã",
      value: _selectedWard?.fullName,
      options: _wards.map(
        (w) => MapEntry(w.fullName, () {
          Navigator.pop(context);
          setState(() => _selectedWard = w);
        }),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return _buildSelector(
      label: "Danh mục",
      value: _selectedCategory?.type,
      options: _categories.map(
        (c) => MapEntry(c.type, () {
          Navigator.pop(context);
          setState(() => _selectedCategory = c);
        }),
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String? value,
    required Iterable<MapEntry<String, Function()>> options,
  }) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(text: value ?? ""),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return ListView(
              children: options
                  .map(
                    (opt) => ListTile(
                      title: Text(opt.key),
                      onTap: opt.value,
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  // ========== Image Picker ==========
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  // ========== Submit ==========
  Future<void> _submit() async {
  // Kiểm tra descriptions có hợp lệ không
  final invalidDescriptions = descriptions.where((desc) => !desc.isValid).toList();
  
  if (invalidDescriptions.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vui lòng nhập đầy đủ tiêu đề và nội dung cho tất cả thông tin chi tiết")),
    );
    return;
  }

  if (descriptions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vui lòng thêm ít nhất 1 thông tin chi tiết")),
    );
    return;
  }

  if (_formKey.currentState!.validate()) {
    final product = ProductRegisterModel(
      id: null,
      name: nameCtrl.text,
      description: descCtrl.text,
      category: _selectedCategory?.id ?? 0,
      minPrice: double.tryParse(minPriceCtrl.text) ?? 0,
      maxPrice: double.tryParse(maxPriceCtrl.text) ?? 0,
      uploadImages: selectedImages,
      province: _selectedProvince?.code ?? "",
      district: _selectedDistrict?.code ?? "",
      ward: _selectedWard?.code ?? "",
      address: addressCtrl.text,
      descriptions: descriptions,
    );

    final success = await ProductService.addProduct(product);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo sản phẩm thành công!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo sản phẩm thất bại!")),
      );
    }
  }
}

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo sản phẩm")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Tên sản phẩm"),
                validator: (v) => v == null || v.isEmpty ? "Nhập tên" : null,
              ),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Mô tả"),
                maxLines: 3,
              ),
              _buildDescriptionInputs(),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minPriceCtrl,
                      decoration: const InputDecoration(labelText: "Giá tối thiểu"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: maxPriceCtrl,
                      decoration: const InputDecoration(labelText: "Giá tối đa"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _buildCategorySelector(),
              _buildProvinceSelector(),
              _buildDistrictSelector(),
              _buildWardSelector(),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: "Địa chỉ chi tiết"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: const Text("Chọn hình ảnh"),
              ),
              Wrap(
                children: selectedImages
                    .map(
                      (img) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.file(
                          img,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Tạo sản phẩm"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
