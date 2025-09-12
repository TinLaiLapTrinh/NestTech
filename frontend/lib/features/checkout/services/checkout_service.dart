import 'dart:convert';
import 'dart:io';

import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/core/configs/headers.dart';
import 'package:frontend/features/product/models/product_detail_model.dart';
import 'package:http/http.dart' as http;

class CheckoutService {
  static Future<dynamic> getCartItems() async {
    final headers = await ApiHeaders.getAuthHeaders();

    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.shoppingCartItems);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List);
    } else {
      throw Exception('Failed to load item: ${response.statusCode}');
    }
  }

  static Future<dynamic> addToCart(int productId, int quantity) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.shoppingCartAddItems);
    final body = {"product": productId, "quantity": quantity};
    final response = await http.post(
      uri,
      headers: header,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Lỗi khi thêm location: ${response.statusCode} - ${response.body}",
      );
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

  static Future<Map<String, dynamic>> addOrder(
    Map<String, dynamic> payload,
  ) async {
    final headers = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.addOrder);

    final response = await http.post(
      uri,
      headers: {...headers, "Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      // decode lỗi server nếu có
      final error = json.decode(response.body);
      throw Exception(
        'Failed to add order: ${response.statusCode}, ${error.toString()}',
      );
    }
  }

  static Future<Rate> ratingProduct(int id, double rate, String content) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.ratingProduct(id));
    final response = await http.post(
      uri,
      headers: header,
      body: jsonEncode({"rate": rate, "content": content}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return Rate.fromJson(data['rate']);
    } else {
      // Lấy message từ response body
      String msg = "Gửi đánh giá thất bại";
      try {
        final data = json.decode(response.body);
        if (data['message'] != null) {
          msg = data['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> orderDetail(int id) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.detailOrder(id));

    final response = await http.get(uri, headers: header);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load order: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> orderRequest(Map<String, String>? params) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(
      ApiConfig.baseUrl + ApiConfig.orderDetail,
    ).replace(queryParameters: params);

    final response = await http.get(uri, headers: header);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] as List<dynamic>;
    } else {
      throw Exception('Failed to load order: ${response.statusCode}');
    }
  }

  static Future<dynamic> orderRequestUpdate(
    int id,
    String deliveryStatus,
  ) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.orderDetailUpdate(id));

    final response = await http.patch(
      uri,
      headers: header,
      body: jsonEncode({"delivery_status": deliveryStatus}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update detail order: ${response.statusCode}');
    }
  }

  static Future<dynamic> orderUpdateStatus(int id, String Status) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.orderDetailUpdate(id));

    final response = await http.patch(
      uri,
      headers: header,
      body: jsonEncode({"delivery_status": Status}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update request order: ${response.statusCode}');
    }
  }

  

  static Future<dynamic> orderDetailRetrieve(int id) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.orderDetailUpdate(id));

    final response = await http.get(uri, headers: header);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to load retrieve request order: ${response.statusCode}',
      );
    }
  }

  static Future<dynamic> orderConfirmImage(int id, File image) async {
    final header = await ApiHeaders.getAuthHeaders();

    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.confirmOrderDetail(id));
    final request = http.MultipartRequest('POST', uri);

    // add headers
    request.headers.addAll(header);

    // add image file
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to confirm order image: ${response.statusCode}, ${response.body}',
      );
    }
  }

  static Future<String> checkPaymentStatus(int orderId) async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/order/$orderId/payment-status/');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print (data);
      return data['payment_status'];
    } else {
      throw Exception('Failed to check payment status');
    }
  }
}
