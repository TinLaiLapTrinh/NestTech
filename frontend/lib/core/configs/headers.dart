import '../utils/token_storage.dart';

class ApiHeaders {
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}