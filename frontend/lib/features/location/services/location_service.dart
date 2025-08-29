import 'dart:convert';

import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/core/configs/headers.dart';
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

  static Future<List<UserLocation>> getLocation()async{
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.getLocation);
    final response = await http.get(uri, headers: header);
    if( response.statusCode ==200){
      final data = json.decode(response.body) as List;
      return data.map((e)=> UserLocation.fromJson(e)).toList();
    }else{
      throw Exception('Fail to get location');
    }
  }

  static Future<dynamic> addLocation(UserLocation userLocation) async {
    try {
      final headers = await ApiHeaders.getAuthHeaders();
      final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.addUserLocation);

      final body = {
        "address": userLocation.address,
        "province": userLocation.provinceCode,
        "ward": userLocation.wardCode,
        "latitude": userLocation.latitude.toString(),
        "longitude": userLocation.longitude.toString(),
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Lỗi khi thêm location: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<LatLng?> geocodeAddress(String address) async {
    final accessToken =
        "pk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZXZsMnhnbzBlbmUyaW9kcjhsb2k2cXAifQ.EmlCJ9BsD-p2C5nr_dlOYA";
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json?access_token=$accessToken&limit=1',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coords = data['features'][0]['geometry']['coordinates'];
        return LatLng(
          coords[1],
          coords[0],
        ); // Mapbox trả về [longitude, latitude]
      }
    }
    return null;
  }
}
