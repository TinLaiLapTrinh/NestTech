import 'dart:convert';

import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/core/configs/headers.dart';
import 'package:http/http.dart' as http;

class CheckoutService {
  static Future<dynamic> getCartItems() async {
    final headers = await ApiHeaders.getAuthHeaders();

    // Build query params nếu có
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.shoppingCartItems);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List);
    } else {
      throw Exception('Failed to load item: ${response.statusCode}');
    }
  }

  static Future<dynamic> updateCartItem(int idItem, int quantity) async {
    final headers = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(
      ApiConfig.baseUrl + ApiConfig.shoppingCartUpdateItem(idItem),
    );
    final response = await http.patch(
      uri,
      headers: headers,
      body: jsonEncode({"quantity": quantity}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to update item: ${response.statusCode}');
    }
  }

  static Future<dynamic> getMyOrder() async {
    final headers = await ApiHeaders.getAuthHeaders();

    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.getOrder);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load item: ${response.statusCode}');
    }
  }

  static Future<dynamic> addOrder() async {
    final headers = await ApiHeaders.getAuthHeaders();


    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.getOrder);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load item: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> orderDetail(int id) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.detailOrder(id));

    final response = await http.get(uri, headers: header);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data
          as Map<String, dynamic>; 
    } else {
      throw Exception('Failed to load order: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> orderRequest() async {
  final header = await ApiHeaders.getAuthHeaders();
  final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.orderRequest);

  final response = await http.get(uri, headers: header);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data as List<dynamic>; // ✅ API trả về danh sách
  } else {
    throw Exception('Failed to load order: ${response.statusCode}');
  }
}

  static Future<dynamic> orderRequestUpdate(int id , String deliveryStatus) async{
     final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.orderRequestUpdate(id));


    final response = await http.patch(
      uri,
      headers: header,
      body: jsonEncode({"delivery_status": deliveryStatus}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data
          as Map<String, dynamic>; 
    } else {
      throw Exception('Failed to update request order: ${response.statusCode}');
    }
  }
}
