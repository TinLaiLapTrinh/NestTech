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
  final categoryCtrl = TextEditingController();
  final provinceCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final wardCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];

  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;
  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProvinces();
  }

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
      setState(() {
        _provinces = provs;
      });
    } catch (e) {
      debugPrint("Error loading provinces: $e");
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    try {
      final dists = await LocationService.getDistricts(provinceCode);
      setState(() {
        _districts = dists;
      });
    } catch (e) {
      debugPrint("Error loading districts: $e");
    }
  }

  Future<void> _loadWards(String districtCode) async {
    try {
      final wards = await LocationService.getWards(districtCode);
      setState(() {
        _wards = wards;
      });
    } catch (e) {
      debugPrint("Error loading wards: $e");
    }
  }

  // ===== Location =====

  Widget _buildProvinceSelector() {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: "Tỉnh/Thành phố",
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(
        text: _selectedProvince?.fullName ?? "",
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return ListView(
              children: _provinces.map((p) {
                return ListTile(
                  title: Text(p.fullName),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      _selectedProvince = p;
                      _selectedDistrict = null;
                      _selectedWard = null;
                      _districts = [];
                      _wards = [];
                    });
                    await _loadDistricts(p.code);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildDistrictSelector() {
    if (_districts.isEmpty) return const SizedBox.shrink();

    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: "Quận/Huyện",
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(
        text: _selectedDistrict?.fullName ?? "",
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return ListView(
              children: _districts.map((d) {
                return ListTile(
                  title: Text(d.fullName),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      _selectedDistrict = d;
                      _selectedWard = null;
                      _wards = [];
                    });
                    await _loadWards(d.code);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildWardSelector() {
    if (_wards.isEmpty) return const SizedBox.shrink();

    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: "Phường/Xã",
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(text: _selectedWard?.fullName ?? ""),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return ListView(
              children: _wards.map((w) {
                return ListTile(
                  title: Text(w.fullName),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedWard = w;
                    });
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: "Danh mục",
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(text: _selectedCategory?.type ?? ""),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return ListView(
              children: _categories.map((c) {
                return ListTile(
                  title: Text(c.type),
                  onTap: () async {
                    Navigator.pop(context); // đóng sheet
                    setState(() {
                      _selectedCategory = c;
                    });
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  List<File> selectedImages = [];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final product = ProductRegisterModel(
        id: null,
        name: nameCtrl.text,
        description: descCtrl.text,
        category: _selectedCategory?.id ?? 0, // ✅ chọn category object
        minPrice: double.tryParse(minPriceCtrl.text) ?? 0,
        maxPrice: double.tryParse(maxPriceCtrl.text) ?? 0,
        uploadImages: selectedImages,
        province: _selectedProvince?.code ?? "", // ✅ chọn tỉnh đã chọn
        district: _selectedDistrict?.code ?? "",
        ward: _selectedWard?.code ?? "",
        address: addressCtrl.text,
      );

      final success = await ProductService.registerSupplier(product);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tạo sản phẩm thành công!")),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Tạo sản phẩm thất bại!")));
      }
    }
  }

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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: "Giá tối thiểu",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: maxPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: "Giá tối đa",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _buildCategorySelector(),
              _buildProvinceSelector(),
              _buildDistrictSelector(),
              _buildWardSelector(),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: const Text("Chọn hình ảnh"),
              ),
              Wrap(
                children: selectedImages.map((img) {
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.file(
                      img,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
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
