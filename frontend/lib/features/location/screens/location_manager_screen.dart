import 'package:flutter/material.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/services/location_service.dart';
import 'package:latlong2/latlong.dart';

class LocationManagerScreen extends StatefulWidget {
  const LocationManagerScreen({super.key});

  @override
  State<LocationManagerScreen> createState() => _LocationManagerScreenState();
}

class _LocationManagerScreenState extends State<LocationManagerScreen> {
  List<UserLocation> _myLocations = [];
  LatLng? _selectedPoint;
  List<Province> _provinces = [];
  List<Ward> _wards = [];
  String? _selectedProvinceCode;
  String? _selectedWardCode;
  bool _isLoading = true;

  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadProvinces();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await LocationService.getLocation();
      setState(() {
        _myLocations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi tải location: $e")));
    }
  }

  Future<void> _addNewLocation(UserLocation loc) async {
    try {
      await LocationService.addLocation(loc);
      await _loadLocations();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thêm địa chỉ thành công")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi thêm địa chỉ: $e")));
    }
  }

  Future<void> _loadProvinces() async {
    final list = await LocationService.getProvinces();
    setState(() => _provinces = list);
  }

 

 void _openAddLocationForm() {
  // Biến tạm trong dialog
  String? tempProvince = _selectedProvinceCode;
  String? tempWard = _selectedWardCode;
  final TextEditingController tempAddressCtrl =
      TextEditingController(text: _addressCtrl.text);
  final TextEditingController tempLatCtrl =
      TextEditingController(text: _latCtrl.text);
  final TextEditingController tempLngCtrl =
      TextEditingController(text: _lngCtrl.text);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Thêm địa chỉ mới"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Địa chỉ cụ thể
                TextField(
                  controller: tempAddressCtrl,
                  decoration: const InputDecoration(labelText: "Địa chỉ cụ thể"),
                ),
                const SizedBox(height: 8),

                // Chọn Tỉnh/Thành phố
                DropdownButton<String>(
                  hint: const Text("Chọn Tỉnh/Thành phố"),
                  value: _provinces.any((p) => p.code == tempProvince)
                      ? tempProvince
                      : null,
                  isExpanded: true,
                  items: _provinces.map((prov) {
                    return DropdownMenuItem<String>(
                      value: prov.code,
                      child: Text(prov.fullName),
                    );
                  }).toList(),
                  onChanged: (val) async {
                    setStateDialog(() {
                      tempProvince = val;
                      tempWard = null; // reset ward khi đổi tỉnh
                      _wards = [];
                    });
                    if (val != null) {
                      final wards = await LocationService.getWards(val);
                      setStateDialog(() {
                        _wards = wards;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Chọn Phường/Xã
                DropdownButton<String>(
                  hint: const Text("Chọn Phường/Xã"),
                  value: _wards.any((w) => w.code == tempWard) ? tempWard : null,
                  isExpanded: true,
                  items: _wards.map((ward) {
                    return DropdownMenuItem<String>(
                      value: ward.code,
                      child: Text(ward.fullName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      tempWard = val;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Latitude & Longitude
                TextField(
                  controller: tempLatCtrl,
                  decoration: const InputDecoration(labelText: "Latitude"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: tempLngCtrl,
                  decoration: const InputDecoration(labelText: "Longitude"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempProvince == null || tempWard == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vui lòng chọn Tỉnh/Phường")),
                  );
                  return;
                }

                // Cập nhật lại state chính
                _selectedProvinceCode = tempProvince;
                _selectedWardCode = tempWard;
                _addressCtrl.text = tempAddressCtrl.text;
                _latCtrl.text = tempLatCtrl.text;
                _lngCtrl.text = tempLngCtrl.text;

                final newLoc = UserLocation(
                  provinceCode: _selectedProvinceCode!,
                  wardCode: _selectedWardCode!,
                  address: _addressCtrl.text,
                  latitude: double.tryParse(_latCtrl.text) ?? 0.0,
                  longitude: double.tryParse(_lngCtrl.text) ?? 0.0,
                );

                _addNewLocation(newLoc);
                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Địa chỉ của tôi")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myLocations.isEmpty
          ? const Center(child: Text("Chưa có địa chỉ nào"))
          : ListView.builder(
              itemCount: _myLocations.length,
              itemBuilder: (context, index) {
                final loc = _myLocations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                    ),
                    title: Text(loc.address),
                    subtitle: Text(
                      "Tỉnh: ${loc.provinceCode}, Xã: ${loc.wardCode}\nLat: ${loc.latitude}, Lng: ${loc.longitude}",
                    ),
                    onTap: () => Navigator.pop(context, loc),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddLocationForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
