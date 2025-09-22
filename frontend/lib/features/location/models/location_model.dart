import 'package:latlong2/latlong.dart';
import 'package:turf/line_segment.dart';

class Province {
  final String code;
  final String name;
  final String fullName;
  final int? administrativeRegion;

  Province({
    required this.code,
    required this.name,
    required this.fullName,
    this.administrativeRegion,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'],
      name: json['name'],
      fullName: json['full_name'],
      administrativeRegion: json['administrative_region'],
    );
  }

  Map<String, dynamic> toJson() => {
    "code": code,
    "name": name,
    "full_name": fullName,
    if (administrativeRegion != null)
      "administrative_region": administrativeRegion,
  };
}

class Ward {
  final String code;
  final String name;
  final String fullName;

  Ward({required this.code, required this.name, required this.fullName});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code'],
      name: json['name'],
      fullName: json['full_name'],
    );
  }
  Map<String, dynamic> toJson() => {
    "code": code,
    "name": name,
    "full_name": fullName,
  };
}

class District {
  final String code;
  final String name;
  final String fullName;

  District({required this.code, required this.name, required this.fullName});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      code: json['code'],
      name: json['name'],
      fullName: json['full_name'],
    );
  }
  Map<String, dynamic> toJson() => {
    "code": code,
    "name": name,
    "full_name": fullName,
  };
}

class UserLocation {
  final Province province;
  final District district;
  final Ward ward;
  final String address;
  final double latitude;
  final double longitude;

  UserLocation({
    required this.province,
    required this.district,
    required this.ward,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      province: Province.fromJson(json['province']),
      district: District.fromJson(json['district']),
      ward: Ward.fromJson(json['ward']),
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "province": province.toJson(),
      "district": district.toJson(),
      "ward": ward.toJson(),
      "address": address,
      "latitude": latitude,
      "longitude": longitude,
    };
  }
}

class SelectedLocationResult {
  final LatLng point;
  final Province province;
  final District district;
  final Ward ward;

  SelectedLocationResult({
    required this.point,
    required this.province,
    required this.district,
    required this.ward,
  });
}


class RouteInfo {
  final List<Position> route;
  final double distance;
  final double duration;

  RouteInfo({
    required this.route,
    required this.distance,
    required this.duration,
  });
}
