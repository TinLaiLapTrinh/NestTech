import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/services/location_service.dart';
import 'package:latlong2/latlong.dart';

class MapFilterScreen extends StatefulWidget {
  final Province? initialProvince;
  final District? initialDistrict;
  final Ward? initialWard;
  final void Function(String address, LatLng point)? onLocationSelected;
  const MapFilterScreen({
    super.key,
    this.initialProvince,
    this.initialDistrict,
    this.initialWard,
    this.onLocationSelected,
  });

  @override
  State<MapFilterScreen> createState() => _MapFilterScreenState();
}

class _MapFilterScreenState extends State<MapFilterScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialPosition = const LatLng(10.762622, 106.660172);

  LatLng? _selectedPoint;

  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];

  String? _selectedProvinceCode;
  String? _selectedDistrictCode;
  String? _selectedWardCode;

  @override
  void initState() {
    super.initState();
    _loadProvinces();

    if (widget.initialProvince != null &&
        widget.initialDistrict != null &&
        widget.initialWard != null) {
      _initSelectedLocation();
    }
  }

  Future<void> _initSelectedLocation() async {
    final address =
        "${widget.initialWard!.fullName}, ${widget.initialDistrict!.fullName}, ${widget.initialProvince!.fullName}";
    final location = await LocationService.geocodeAddress(address);
    if (location != null) {
      setState(() => _selectedPoint = location);
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _mapController.move(_selectedPoint!, 17),
      );
    }
  }

  Future<void> _loadProvinces() async {
    final list = await LocationService.getProvinces();
    setState(() => _provinces = list);

    if (widget.initialProvince != null) {
      _selectedProvinceCode = widget.initialProvince!.code;
      await _loadDistricts(_selectedProvinceCode!);

      if (widget.initialDistrict != null) {
        _selectedDistrictCode = widget.initialDistrict!.code;
        await _loadWards(_selectedDistrictCode!);

        if (widget.initialWard != null) {
          _selectedWardCode = widget.initialWard!.code;
        }
      }
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    final list = await LocationService.getDistricts(provinceCode);
    setState(() => _districts = list);
  }

  Future<void> _loadWards(String districtCode) async {
    final list = await LocationService.getWards(districtCode);
    setState(() {
      _wards = list;
      _selectedWardCode ??= null;
    });
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() => _selectedPoint = point);

    // Lấy thông tin địa chỉ full từ tọa độ
    final locationInfo = await LocationService.reverseGeocodeFull(
      point.latitude,
      point.longitude,
    );

    if (locationInfo != null) {
      final provinceName = locationInfo['province'];
      final districtName = locationInfo['district'];
      final wardName = locationInfo['ward'];

      // Cập nhật Province
      final province = _provinces.firstWhere(
        (p) => p.name == provinceName,
        orElse: () => _provinces.first,
      );
      setState(() => _selectedProvinceCode = province.code);
      await _loadDistricts(province.code);

      // Cập nhật District
      final district = _districts.firstWhere(
        (d) => d.fullName == districtName,
        orElse: () => _districts.first,
      );
      setState(() => _selectedDistrictCode = district.code);
      await _loadWards(district.code);

      // Cập nhật Ward
      final ward = _wards.firstWhere(
        (w) => w.fullName == wardName,
        orElse: () => _wards.first,
      );
      setState(() => _selectedWardCode = ward.code);

      final address =
          "${ward.fullName}, ${district.fullName}, ${province.fullName}";

      // Gọi callback nếu có
      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(address, _selectedPoint!);
      }

      // Hiển thị snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bạn đã chọn: $address")));
    }
  }

  Future<void> _goToSelectedLocation() async {
    if (_selectedProvinceCode != null &&
        _selectedDistrictCode != null &&
        _selectedWardCode != null) {
      final province = _provinces.firstWhere(
        (p) => p.code == _selectedProvinceCode,
      );
      final district = _districts.firstWhere(
        (d) => d.code == _selectedDistrictCode,
      );
      final ward = _wards.firstWhere((w) => w.code == _selectedWardCode);

      final address =
          "${ward.fullName}, ${district.fullName}, ${province.fullName}";
      final LatLng? location = await LocationService.geocodeAddress(address);

      if (location != null) {
        setState(() => _selectedPoint = location);
        _mapController.move(location, 17);

        // Gọi callback
        if (widget.onLocationSelected != null) {
          widget.onLocationSelected!(address, location);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bản đồ chi tiết theo Tỉnh/Huyện/Xã")),
      body: Column(
        children: [
          _buildProvinceDropdown(),
          _buildDistrictDropdown(),
          _buildWardDropdown(),
          _buildMap(),
        ],
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    return DropdownButton<String>(
      hint: const Text("Chọn Tỉnh"),
      value: _selectedProvinceCode,
      items: _provinces
          .map((p) => DropdownMenuItem(value: p.code, child: Text(p.name)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedProvinceCode = val;
          _selectedDistrictCode = null;
          _districts = [];
          _selectedWardCode = null;
          _wards = [];
        });
        if (val != null) _loadDistricts(val);
      },
    );
  }

  Widget _buildDistrictDropdown() {
    return DropdownButton<String>(
      hint: const Text("Chọn Huyện"),
      value: _selectedDistrictCode,
      items: _districts
          .map((d) => DropdownMenuItem(value: d.code, child: Text(d.fullName)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedDistrictCode = val;
          _selectedWardCode = null;
          _wards = [];
        });
        if (val != null) _loadWards(val);
      },
    );
  }

  Widget _buildWardDropdown() {
    return DropdownButton<String>(
      hint: const Text("Chọn Xã"),
      value: _selectedWardCode,
      items: _wards
          .map((w) => DropdownMenuItem(value: w.code, child: Text(w.fullName)))
          .toList(),
      onChanged: (val) {
        setState(() => _selectedWardCode = val);
        _goToSelectedLocation();
      },
    );
  }

  Widget _buildMap() {
    return Expanded(
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
          onTap: (tapPosition, point) => _onMapTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}",
            additionalOptions: {
              'accessToken':
                  'pk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZXZsMnhnbzBlbmUyaW9kcjhsb2k2cXAifQ.EmlCJ9BsD-p2C5nr_dlOYA',
              'id': 'mapbox/streets-v11',
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
    );
  }
}
