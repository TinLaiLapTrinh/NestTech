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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm vị trí thành công')),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu vị trí thất bại: $e')),
        );
      }
      print('Lỗi khi lưu location: $e');
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm vị trí mới'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildProvinceSelector(),
            const SizedBox(height: 8),
            _buildDistrictSelector(),
            const SizedBox(height: 8),
            _buildWardSelector(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openMapScreen,
              child: const Text('Chọn trên bản đồ'),
            ),
            if (_selectedPoint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Đã chọn: (${_selectedPoint!.latitude}, ${_selectedPoint!.longitude})',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        if (_selectedPoint != null)
          ElevatedButton(
            onPressed: _saveLocation,
            child: const Text('Lưu'),
          ),
      ],
    );
  }
}
