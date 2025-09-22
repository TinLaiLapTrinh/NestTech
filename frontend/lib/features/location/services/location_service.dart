import 'dart:convert';

import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/core/configs/headers.dart';
import 'package:frontend/features/location/models/location_model.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:turf/line_segment.dart';

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

  static Future<List<District>> getDistricts(String provinceCode) async {
    final url = Uri.parse(
      ApiConfig.baseUrl + ApiConfig.getDistrict(provinceCode),
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => District.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load district');
    }
  }

  static Future<List<Ward>> getWards(String districtId) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getWards(districtId));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Ward.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load wards');
    }
  }

  static Future<List<UserLocation>> getLocation() async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.getLocation);
    final response = await http.get(uri, headers: header);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => UserLocation.fromJson(e)).toList();
    } else {
      throw Exception('Fail to get location');
    }
  }

  static Future<dynamic> getShippingRoute(
    int originRegion,
    int destinationRegion,
  ) async {
    try {
      final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.getShippingRoute)
          .replace(
            queryParameters: {
              "origin": originRegion.toString(),
              "destination": destinationRegion.toString(),
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load shipping route: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception("Error fetching shipping route: $e");
    }
  }

  static Future<dynamic> addLocation(UserLocation userLocation) async {
    try {
      final headers = await ApiHeaders.getAuthHeaders();
      final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.addUserLocation);

      final body = {
        "address": userLocation.address,
        "province": userLocation.province.code,
        "district": userLocation.district.code,
        "ward": userLocation.ward.code,
        "latitude": userLocation.latitude,
        "longitude": userLocation.longitude,
      };

      print('Sending body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Lỗi khi thêm location: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print('Add location error: $e');
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
        return LatLng(coords[1], coords[0]);
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> reverseGeocodeFull(
    double latitude,
    double longitude,
  ) async {
    final accessToken =
        "pk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZXZsMnhnbzBlbmUyaW9kcjhsb2k2cXAifQ.EmlCJ9BsD-p2C5nr_dlOYA";

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$accessToken&limit=1',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        final context = feature['context'] ?? [];

        String? province;
        String? district;
        String? ward;

        for (var item in context) {
          final id = item['id'] as String;
          if (id.startsWith('region')) {
            province = item['text'];
          } else if (id.startsWith('district')) {
            district = item['text'];
          } else if (id.startsWith('place') || id.startsWith('locality')) {
            ward = item['text'];
          }
        }

        return {
          "province": province,
          "district": district,
          "ward": ward,
          "fullAddress": feature['place_name'],
        };
      }
    }
    return null;
  }

  Future<RouteInfo> getRouteFromMapbox(
    Position start,
    Position end,
    String accessToken,
  ) async {
    final url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/${start.lng},${start.lat};${end.lng},${end.lat}?geometries=geojson&access_token=$accessToken";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      final distance = (data['routes'][0]['distance'] as num).toDouble();
      final duration = (data['routes'][0]['duration'] as num).toDouble();

      final routePositions = coords.map((c) => Position(c[0], c[1])).toList();

      return RouteInfo(
        route: routePositions,
        distance: distance,
        duration: duration,
      );
    } else {
      throw Exception("Failed to load route");
    }
  }

  Future<geo.Position> _getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    // Kiểm tra service GPS
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS chưa bật');
    }

    // Kiểm tra quyền
    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối');
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị chặn vĩnh viễn');
    }

    // Lấy vị trí
    return await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
  }
}
