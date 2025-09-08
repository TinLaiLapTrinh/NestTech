import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/configs/api_config.dart';
import '../../../core/configs/headers.dart';
import '../models/user_register_model.dart';

class UserService {
  static Future<List<dynamic>> profile()async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.profileUser);
    final response= await http.get(url,headers: headers);

    if(response.statusCode==200){
      final data = json.decode(response.body);
      return data;
    }else {
      throw Exception('Failed to load user info');
    }

  }
  static Future<dynamic> customerRegister(UserModel user, {String? password}) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.customerRegister);

    var request = http.MultipartRequest('POST', url);

    request.fields['username'] = user.username;
    request.fields['password'] = password ?? "123456"; 
    request.fields['first_name'] = user.firstName;
    request.fields['last_name'] = user.lastName;
    if (user.dob != null) request.fields['dob'] = user.dob!;
    request.fields['email'] = user.email;
    if (user.address != null) request.fields['address'] = user.address!;
    if (user.phoneNumber != null) request.fields['phone_number'] = user.phoneNumber!;

    if (user.avatar != null) {
      var multipartFile = await http.MultipartFile.fromPath('avatar', user.avatar!.path);
      request.files.add(multipartFile);
    }


    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to register account: ${response.body}');
    }
  }
   static Future<bool> registerSupplier(SupplierRegisterRequest request) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.supplierRegister);


    final multipartRequest = await request.toMultipartRequest(url);

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

     if (response.statusCode == 200 || response.statusCode == 201) {
    return true; // thành công
  } else {
    debugPrint("Đăng ký supplier thất bại: ${response.body}");
    return false; // thất bại
  }
  }

  Future<void> saveFcmToken(String token) async {
   final header = await ApiHeaders.getAuthHeaders();
  final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.saveFcmToken);
  final response = await http.post(
    url,
    headers: header,
    body: jsonEncode({'token': token}),
  );

  if (response.statusCode == 200) {
    print("FCM token saved successfully!");
  } else {
    print("Failed to save FCM token: ${response.body}");
  }
}

}
