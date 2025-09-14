import 'dart:convert';

import 'package:frontend/core/configs/headers.dart';
import 'package:frontend/features/user/models/user_model.dart';
import 'package:frontend/features/user/provider/user_provider.dart';
import 'package:http/http.dart' as http;

import '../../../core/configs/api_config.dart';
import '../../../core/utils/token_storage.dart';

class AuthService {
  static Future<bool> login({
    required String username,
    required String password,
    required UserProvider userProvider, 
  }) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.tokenEndpoint);
    final response = await http.post(
      url,
      body: {
        'username': username,
        'password': password,
        'client_id': 'NM7isb5kxukRzJcLAoIiZB6Sml1YL0EnalzISf6j',
        'client_secret': 'SjYIqoy7hSpzKw9FEc81uVT3ssTiKlu3Vc3PLtra5pGIx2WZSZPOYd0ClwtG8DFvVa8VTAK6ZH1ZuPzYeCuGqX9VBQcQxj8y35NTGjf6CTHdVNnDXFmT0auErp9PlXEJ',
        'grant_type': 'password',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      await TokenStorage.saveToken(token);
      final headers = await ApiHeaders.getAuthHeaders();

      final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.profileUser);
      final userResponse = await http.get(uri, headers: headers);

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final user = UserModel.fromJson(userData);
        userProvider.setUser(user);
      }
      return true;
    }
    return false;
  }
}
