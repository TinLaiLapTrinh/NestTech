import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/services/location_service.dart';
import 'package:latlong2/latlong.dart';

class MapFilterScreen extends StatefulWidget {
  const MapFilterScreen({super.key});

  @override
  State<MapFilterScreen> createState() => _MapFilterScreenState();
}

class _MapFilterScreenState extends State<MapFilterScreen> {
  final MapController _mapController = MapController();

  final LatLng _initialPosition = const LatLng(10.762622, 106.660172);
  LatLng? _selectedPoint;

  List<Province> _provinces = [];
  List<Ward> _wards = [];
  String? _selectedProvinceCode;
  String? _selectedWardCode;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    final list = await LocationService.getProvinces();
    setState(() => _provinces = list);
  }

  Future<void> _loadWards(String provinceCode) async {
    final list = await LocationService.getWards(provinceCode);
    setState(() {
      _wards = list;
      _selectedWardCode = null;
    });
  }

  Future<void> _goToSelectedLocation() async {
    if (_selectedProvinceCode != null && _selectedWardCode != null) {
      final province = _provinces.firstWhere(
        (p) => p.code == _selectedProvinceCode,
      );
      final ward = _wards.firstWhere((w) => w.code == _selectedWardCode);
      final address = " ${province.fullName}, ${ward.fullName}";

      final LatLng? location = await LocationService.geocodeAddress(address);
      if (location != null) {
        setState(() => _selectedPoint = location);
        _mapController.move(location, 17); // zoom chi tiết hơn
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bản đồ chi tiết theo Tỉnh/Xã")),
      body: Column(
        children: [
          // Chọn tỉnh
          DropdownButton<String>(
            hint: const Text("Chọn Tỉnh"),
            value: _selectedProvinceCode,
            items: _provinces
                .map(
                  (p) => DropdownMenuItem(value: p.code, child: Text(p.name)),
                )
                .toList(),
            onChanged: (val) {
              setState(() => _selectedProvinceCode = val);
              if (val != null) _loadWards(val);
            },
          ),
          // Chọn xã
          DropdownButton<String>(
            hint: const Text("Chọn Xã/Huyện"),
            value: _selectedWardCode,
            items: _wards
                .map(
                  (w) =>
                      DropdownMenuItem(value: w.code, child: Text(w.fullName)),
                )
                .toList(),
            onChanged: (val) {
              setState(() => _selectedWardCode = val);
              _goToSelectedLocation();
            },
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 20,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
                // 👇 Thêm onTap
                onTap: (tapPosition, latlng) {
                  setState(() {
                    _selectedPoint = latlng;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken':
                        'pk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZXZsMnhnbzBlbmUyaW9kcjhsb2k2cXAifQ.EmlCJ9BsD-p2C5nr_dlOYA',
                    'id':
                        'mapbox/streets-v11', // style chi tiết, có nhãn cửa hàng
                  },
                ),
                MarkerLayer(
                  markers: [
                    if (_selectedPoint != null)
                      Marker(
                        point: _selectedPoint!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
