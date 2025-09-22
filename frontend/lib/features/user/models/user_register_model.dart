import 'dart:io';

import 'package:http/http.dart';

class UserModelRegister {
  final int? id;
  final String username;
  final String firstName;
  final String lastName;
  final String? dob;
  final String email;
  final String? address;
  final File? avatar; 
  final String? phoneNumber;
  final String? userType;
  final int? followCount;

  UserModelRegister({
    this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.dob,
    required this.email,
    this.address,
    this.avatar,
    this.phoneNumber,
    this.followCount,
    this.userType,
  });

  factory UserModelRegister.fromJson(Map<String, dynamic> json) {
    return UserModelRegister(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dob: json['dob'],
      email: json['email'],
      address: json['address'],
      userType: json['user_type'],
      
      avatar: null,
      phoneNumber: json['phone_number'],
    );
  }
}

class SupplierRegisterRequest {
  
  String username;
  String password;
  String firstName;
  String lastName;
  String? dob;
  String email;
  String? address;
  String? phoneNumber;
  String? userType;
  File? avatar;
  int? followCount;


  String productName;
  String productDescription;
  String productCategory;
  String productMinPrice;
  String productMaxPrice;
  String productProvince;
  String productDistrict;
  String productWard;
  String productAddress;
  List<File> productImages;

  SupplierRegisterRequest({
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.dob,
    required this.email,
    this.address,
    this.phoneNumber,
    this.avatar,
    this.userType,
    required this.productName,
    required this.productDescription,
    required this.productCategory,
    required this.productMinPrice,
    required this.productMaxPrice,
    required this.productProvince,
    required this.productDistrict,
    required this.productWard,
    required this.productAddress,
    required this.productImages,
  });

  Future<MultipartRequest> toMultipartRequest(Uri uri) async {
    final request = MultipartRequest('POST', uri);


    request.fields['username'] = username;
    request.fields['password'] = password;
    request.fields['first_name'] = firstName;
    request.fields['last_name'] = lastName;
    if (dob != null) request.fields['dob'] = dob!;
    request.fields['email'] = email;
    if (address != null) request.fields['address'] = address!;
    if (phoneNumber != null) request.fields['phone_number'] = phoneNumber!;

    if (avatar != null) {
      request.files.add(await MultipartFile.fromPath("avatar", avatar!.path));
    }

    request.fields['product_name'] = productName;
    request.fields['product_description'] = productDescription;
    request.fields['product_category'] = productCategory;
    request.fields['product_min_price'] = productMinPrice;
    request.fields['product_max_price'] = productMaxPrice;
    request.fields['product_province'] = productProvince;
     request.fields['product_district'] = productDistrict;
    request.fields['product_ward'] = productWard;
    request.fields['product_address'] = productAddress;

    for (var img in productImages) {
      request.files.add(
        await MultipartFile.fromPath("product_upload_images", img.path),
      );
    }

    return request;
  }
}
