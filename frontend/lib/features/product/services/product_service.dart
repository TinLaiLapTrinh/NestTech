import 'dart:convert';

import 'package:frontend/features/product/models/product_detail_model.dart';
import 'package:frontend/features/product/models/product_model.dart';
import 'package:frontend/features/product/models/product_option_model.dart';
import 'package:http/http.dart' as http;

import '../../../core/configs/api_config.dart';
import '../../../core/configs/headers.dart';

class ProductService {
  static Future<List<ProductModel>> getProducts({
    Map<String, String>? params,
  }) async {
    final headers = await ApiHeaders.getAuthHeaders();

    // Build query params nếu có
    final uri = Uri.parse(
      ApiConfig.baseUrl + ApiConfig.productList,
    ).replace(queryParameters: params);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  static Future<List<ProductModel>> getMyProduct() async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.myProductList);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);


      List<ProductModel> products = (data['results'] as List)
          .map((item) => ProductModel.fromJson(item))
          .toList();

      return products;
    } else {
      throw Exception('Failed to load my products');
    }
  }

  static Future<List<dynamic>> getVariants(int id) async{
     final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.productVariants(id));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data;
    } else {
      throw Exception('Failed to get variants');
    }
  }

  static Future<List<dynamic>> getOption(int id) async{
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.options(id));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data;
    } else {
      throw Exception('Failed to get variants');
    }
  }

  static Future<List<CategoryModel>> getCategory() async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.categoryList);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get category');
    }
  }

  static Future<ProductDetailModel> getProductDetail(int id) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.productDetail(id));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ProductDetailModel.fromJson(data);
    } else {
      throw Exception('Failed to get product detail');
    }
  }

  static Future<dynamic> deleteProduct(int id) async {
    final header = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.productDelete(id));
    final response = await http.delete(url, headers: header);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to delete product detail');
    }
  }

  static Future<dynamic> productOptionSetup(
    int id,
    List<OptionModel> options,
  ) async {
    final header = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.productOptionSetup(id));

    final body = jsonEncode({
      "options": options.map((e) => e.toJson()).toList(),
    });

    final response = await http.post(
      url,
      headers: {...header, "Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed: ${response.statusCode} - ${response.body}");
    }
  }
}
