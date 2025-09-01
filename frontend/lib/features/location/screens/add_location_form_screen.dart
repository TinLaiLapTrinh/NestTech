import 'package:flutter/material.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/screens/map_screen.dart';
import 'package:frontend/features/location/services/location_service.dart';
import 'package:latlong2/latlong.dart';

class AddLocationPopup extends StatefulWidget {
  const AddLocationPopup({super.key});

  @override
  State<AddLocationPopup> createState() => _AddLocationPopupState();
}

class _AddLocationPopupState extends State<AddLocationPopup> {
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;
  LatLng? _selectedPoint;
  String? _address;

  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    final provinces = await LocationService.getProvinces();
    if (!mounted) return;
    setState(() => _provinces = provinces);
  }

  Future<void> _loadDistricts(String provinceCode) async {
    final districts = await LocationService.getDistricts(provinceCode);
    if (!mounted) return;
    setState(() => _districts = districts);
  }

  Future<void> _loadWards(String districtCode) async {
    final wards = await LocationService.getWards(districtCode);
    if (!mounted) return;
    setState(() => _wards = wards);
  }

  Future<void> _openMapScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapFilterScreen(
          initialProvince: _selectedProvince,
          initialDistrict: _selectedDistrict,
          initialWard: _selectedWard,
          onLocationSelected: (address, point) {
            setState(() {
              _address = address;
              _selectedPoint = point;
            });
            print("Address: $address");
            print("Coordinates: ${point.latitude}, ${point.longitude}");
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedProvince = result['province'];
        _selectedDistrict = result['district'];
        _selectedWard = result['ward'];
        _selectedPoint = result['latLng'];
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null ||
        _address == null ||
        _selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Vui lòng chọn đầy đủ Tỉnh/Huyện/Xã và vị trí trên bản đồ",
          ),
        ),
      );
      return;
    }

    final userLocation = UserLocation(
      province: _selectedProvince!,
      district: _selectedDistrict!,
      ward: _selectedWard!,
      address: _address!,
      latitude: _selectedPoint!.latitude,
      longitude: _selectedPoint!.longitude,
    );

    try {
      await LocationService.addLocation(userLocation);
      if (mounted) {
        Navigator.pop(context, true); 
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lưu vị trí thất bại: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm vị trí mới'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButton<Province>(
              hint: const Text("Chọn tỉnh"),
              value: _selectedProvince,
              items: _provinces
                  .map(
                    (prov) =>
                        DropdownMenuItem(value: prov, child: Text(prov.name)),
                  )
                  .toList(),
              onChanged: (province) {
                if (province == null) return;
                setState(() {
                  _selectedProvince = province;
                  _selectedDistrict = null;
                  _selectedWard = null;
                  _districts = [];
                  _wards = [];
                });
                _loadDistricts(province.code);
              },
            ),
            DropdownButton<District>(
              hint: const Text("Chọn huyện"),
              value: _selectedDistrict,
              items: _districts
                  .map(
                    (d) => DropdownMenuItem(value: d, child: Text(d.fullName)),
                  )
                  .toList(),
              onChanged: (district) {
                if (district == null) return;
                setState(() {
                  _selectedDistrict = district;
                  _selectedWard = null;
                  _wards = [];
                });
                _loadWards(district.code);
              },
            ),
            DropdownButton<Ward>(
              hint: const Text("Chọn xã"),
              value: _selectedWard,
              items: _wards
                  .map(
                    (w) => DropdownMenuItem(value: w, child: Text(w.fullName)),
                  )
                  .toList(),
              onChanged: (ward) {
                if (ward == null) return;
                setState(() => _selectedWard = ward);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openMapScreen,
              child: const Text('Chọn trên bản đồ'),
            ),
            if (_selectedPoint != null)
              Text(
                'Đã chọn: (${_selectedPoint!.latitude}, ${_selectedPoint!.longitude})',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
        if (_selectedPoint != null)
          ElevatedButton(onPressed: _saveLocation, child: const Text('Lưu')),
      ],
    );
  }
}
