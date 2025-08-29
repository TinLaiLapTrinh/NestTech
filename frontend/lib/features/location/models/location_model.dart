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
