

class Province {
  final String code;
  final String name;
  final String fullName;

  Province({required this.code, required this.name, required this.fullName});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'],
      name: json['name'],
      fullName: json['full_name'],
    );
  }
}

class Ward {
  final String code;
  final String fullName;

  Ward({required this.code, required this.fullName});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code'],
      fullName: json['full_name'],
    );
  }
}

class UserLocation {
  final String provinceCode;
  final String wardCode;
  final String address;
  final double latitude;
  final double longitude;

  UserLocation({
    required this.provinceCode,
    required this.wardCode,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      provinceCode: json['province'] ?? '',
      wardCode: json['ward'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "province": provinceCode,
      "ward": wardCode,
      "address": address,
      "latitude": latitude,
      "longitude": longitude,
    };
  }
}

