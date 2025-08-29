import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/core/configs/headers.dart';
import 'package:http/http.dart' as http;

import '../models/user_register_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> fetchCurrentUser(String token) async {
    try {
      final headers = await ApiHeaders.getAuthHeaders();
      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.profileUser);
      final response = await http.get(url, headers: headers);
      final userData = json.decode(response.body);
      final user = UserModel.fromJson(userData);
      setUser(user);
    } catch (e) {
      clearUser();
    }
  }
}
