import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/services/location_service.dart';
import 'package:frontend/features/product/models/product_model.dart';
import 'package:frontend/features/product/services/product_service.dart';
import 'package:frontend/features/user/models/user_register_model.dart';
import 'package:frontend/features/user/services/user_service.dart';
import 'package:image_picker/image_picker.dart';

class SupplierRegisterScreen extends StatefulWidget {
  const SupplierRegisterScreen({super.key});

  @override
  State<SupplierRegisterScreen> createState() => _SupplierRegisterScreenState();
}

class _SupplierRegisterScreenState extends State<SupplierRegisterScreen> {
  int _currentStep = 0;


  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();


  final _productNameCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();


  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];

  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;
  CategoryModel? _selectedCategory;
  final _productAddressCtrl = TextEditingController();


  final List<File> _images = [];


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
                    Navigator.pop(context); 
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _submitForm() async {
    final req = SupplierRegisterRequest(
      username: _usernameCtrl.text,
      password: _passwordCtrl.text,
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      dob: _dobCtrl.text,
      email: _emailCtrl.text,
      address: _addressCtrl.text,
      phoneNumber: _phoneCtrl.text,
      productName: _productNameCtrl.text,
      productDescription: _descriptionCtrl.text,
      productMinPrice: _minPriceCtrl.text,
      productMaxPrice: _maxPriceCtrl.text,
      productCategory: _selectedCategory!.id.toString(),
      productProvince: _selectedProvince!.code,
      productDistrict: _selectedDistrict!.code,
      productWard: _selectedWard!.code,
      productAddress: _productAddressCtrl.text,
      productImages: _images,
    );

    final result = await UserService.registerSupplier(req);

    if (result) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đăng ký supplier thành công!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đăng ký supplier thất bại!")));

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký Shop bán sản phẩm")),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep += 1);
          } else {
            _submitForm();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          
          Step(
            title: const Text("Thông tin người dùng"),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                TextField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: "First Name"),
                ),
                TextField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: "Last Name"),
                ),
                TextField(
                  controller: _dobCtrl,
                  decoration: const InputDecoration(labelText: "Ngày sinh"),
                ),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: "Địa chỉ"),
                ),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: "Số điện thoại"),
                ),
              ],
            ),
          ),

          Step(
            title: const Text("Thông tin sản phẩm"),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                TextField(
                  controller: _productNameCtrl,
                  decoration: const InputDecoration(labelText: "Tên sản phẩm"),
                ),
                TextField(
                  controller: _minPriceCtrl,
                  decoration: const InputDecoration(labelText: "Giá tối thiểu"),
                ),
                TextField(
                  controller: _maxPriceCtrl,
                  decoration: const InputDecoration(labelText: "Giá tối đa"),
                ),
                TextField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: "Mô tả sản phẩm",
                  ),
                ),
                _buildCategorySelector(),
              ],
            ),
          ),


          Step(
            title: const Text("Vị trí sản phẩm"),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                _buildProvinceSelector(),
                const SizedBox(height: 12),
                _buildDistrictSelector(),
                const SizedBox(height: 12),
                _buildWardSelector(),
                const SizedBox(height: 12),
                TextField(
                  controller: _productAddressCtrl,
                  decoration: const InputDecoration(
                    labelText: "Địa chỉ chi tiết",
                  ),
                ),
              ],
            ),
          ),


          Step(
            title: const Text("Hình ảnh minh họa"),
            isActive: _currentStep >= 3,
            content: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Chọn ảnh"),
                ),
                Wrap(
                  spacing: 8,
                  children: _images
                      .map(
                        (img) => Image.file(
                          img,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
