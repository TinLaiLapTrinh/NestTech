import 'package:flutter/material.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:frontend/features/location/screens/add_location_form_screen.dart';
import 'package:frontend/features/location/services/location_service.dart';

class LocationManagerScreen extends StatefulWidget {
  final bool isSelecting;

  const LocationManagerScreen({super.key, this.isSelecting = false});

  @override
  State<LocationManagerScreen> createState() => _LocationManagerScreenState();
}

class _LocationManagerScreenState extends State<LocationManagerScreen> {
  List<UserLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await LocationService.getLocation();
      if (!mounted) return;
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Load locations failed: $e');
    }
  }

  Future<void> _addNewLocation() async {
    await showDialog<UserLocation>(
      context: context,
      builder: (_) => const AddLocationPopup(),
    );

      _loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý vị trí')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final loc = _locations[index];
                return ListTile(
                  title: Text(loc.address),
                  subtitle: Text(
                    '${loc.province.name} - ${loc.district.name} - ${loc.ward.name}',
                  ),
                  onTap: widget.isSelecting
                      ? () {
                          // Trả về location khi chọn
                          Navigator.pop(context, loc);
                        }
                      : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewLocation,
        child: const Icon(Icons.add),
      ),
    );
  }
}
