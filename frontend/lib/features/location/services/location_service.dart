import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<List<Province>> getProvinces() async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getProvinces);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Province.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load provinces');
    }
  }

  static Future<List<Ward>> getWards(String provinceCode) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getWards(provinceCode));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Ward.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load wards');
    }
  }

   static Future<LatLng?> geocodeAddress(String address) async {
    final accessToken = dotenv.env['MAPBOX_KEY'];
    final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json?access_token=$accessToken&limit=1');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coords = data['features'][0]['geometry']['coordinates'];
        return LatLng(coords[1], coords[0]); // Mapbox trả về [longitude, latitude]
      }
    }
    return null; // không tìm thấy
  }

  
}
