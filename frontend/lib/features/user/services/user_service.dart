import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/features/user/models/user_model.dart';
import 'package:http/http.dart' as http;

import '../../../core/configs/api_config.dart';
import '../../../core/configs/headers.dart';
import '../models/user_register_model.dart';

class UserService {
  static Future<List<dynamic>> profile() async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.profileUser);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load user info');
    }
  }

  static Future<dynamic> customerRegister(
    UserModelRegister user, {
    String? password,
  }) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.customerRegister);

    var request = http.MultipartRequest('POST', url);

    request.fields['username'] = user.username;
    request.fields['password'] = password ?? "123456";
    request.fields['first_name'] = user.firstName;
    request.fields['last_name'] = user.lastName;
    if (user.dob != null) request.fields['dob'] = user.dob!;
    request.fields['email'] = user.email;
    if (user.address != null) request.fields['address'] = user.address!;
    if (user.phoneNumber != null)
      request.fields['phone_number'] = user.phoneNumber!;

    if (user.avatar != null) {
      var multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        user.avatar!.path,
      );
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
    } else {
      print("Failed to save FCM token: ${response.body}");
    }
  }

 static Future<UserModel> getDetailUser(int id) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.userDetail(id));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to load user detail (status: ${response.statusCode})');
    }
  }



 static Future<dynamic> verification(File idCard) async {
    final headers = await ApiHeaders.getAuthHeaders(); 
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.verification);

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',       
          idCard.path,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return response.body; 
    } else {
      throw Exception(
          "Xác minh thất bại {không đúng định dạng ảnh hoặc lỗi, vui lòng chụp lại}");
    }
  }

  static Future<List<UserModel>> getFollowers() async {
    final headers = await ApiHeaders.getAuthHeaders(); 
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.followers);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<UserModel> followers = (data['results'] as List)
          .map((item) => UserModel.fromJson(item))
          .toList();
      return followers;
    } else {
      throw Exception('Failed to load followers');
    }
  }

  /// Lấy danh sách followings của user hiện tại
  static Future<List<UserModel>> getFollowings() async {
    final headers = await ApiHeaders.getAuthHeaders(); 
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.followings);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<UserModel> followings = (data['results'] as List)
          .map((item) => UserModel.fromJson(item))
          .toList();
      return followings;
    } else {
      throw Exception('Failed to load followings');
    }
  }

  /// Hủy follow user có id
  static Future<bool> unFollow(int id) async {
    final headers = await ApiHeaders.getAuthHeaders(); 
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.unFollow(id));
    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to unfollow user');
    }
  }

    static Future<bool> follow(int id) async {
      final headers = await ApiHeaders.getAuthHeaders(); 
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.follow(id));
    final response = await http.post(url, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to follow user');
    }
  }

  /// Kiểm tra có đang follow user hay không
  static Future<bool> isFollowing(int id) async {
    final headers = await ApiHeaders.getAuthHeaders(); 
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.isFollowing(id));
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_following'] as bool;
    } else {
      throw Exception('Failed to check following status');
    }
  }
}
