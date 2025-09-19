import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/features/product/models/product_detail_model.dart';
import 'package:frontend/features/product/models/product_model.dart';
import 'package:frontend/features/product/models/product_option_model.dart';
import 'package:frontend/features/product/models/product_register_model.dart';
import 'package:http/http.dart' as http;

import '../../../core/configs/api_config.dart';
import '../../../core/configs/headers.dart';

class ProductService {
  static Future<List<ProductModel>> getProducts({
    Map<String, String>? params,
  }) async {
    final headers = await ApiHeaders.getAuthHeaders();

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

  static Future<List<ProductModel>> getMyProduct({
    int page = 1,
    bool hideDone = false,
    String? deliveryStatus,
  }) async {
    final headers = await ApiHeaders.getAuthHeaders();

    final queryParams = {
      "page": page.toString(),
      "hide_done": hideDone.toString(), // true/false
      if (deliveryStatus != null) "delivery_status": deliveryStatus,
    };

    final uri = Uri.parse(
      "${ApiConfig.baseUrl}${ApiConfig.myProductList}",
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data["results"] as List;
      return results.map((e) => ProductModel.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load my products');
    }
  }

  static Future<bool> updateDescriptions(
    List<Description> descriptions,
    int id,
  ) async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.productDetail(id));
    final body = jsonEncode({
      "description_product": descriptions.map((d) => d.toJson()).toList(),
    });
    print("Mẫu gửi về: $body");

    final res = await http.patch(
      url,
      headers: {
        ...headers,
        "Content-Type": "application/json", // 🔑 bắt buộc
      },
      body: body,
    );

    if (res.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to get product detail');
    }
  }

  static Future<List<ProductModel>> getShopProducts(int id) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.shopProducts(id));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<ProductModel> products = (data['results'] as List)
          .map((item) => ProductModel.fromJson(item))
          .toList();

      return products;
    } else {
      throw Exception('Failed to load shop products');
    }
  }

  static Future<List<ProductModel>> getMyProductDeteted() async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.productsDeleted);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<ProductModel> products = (data['results'] as List)
          .map((item) => ProductModel.fromJson(item))
          .toList();

      return products;
    } else if (response.statusCode == 404) {
      // Hết sản phẩm
      return [];
    } else {
      throw Exception('Failed to load my products');
    }
  }

  static Future<List<Map<String, dynamic>>> generateVariants(int id) async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.addProductVariant(id));

    final res = await http.post(url, headers: headers);
    if (res.statusCode == 200) {
      final data = json.decode(res.body); // decode JSON string
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Lỗi generate variant: ${res.reasonPhrase}");
    }
  }

  static Future<List<ProductVariant>> getVariants(int id) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.productVariants(id));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => ProductVariant.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get variants');
    }
  }

  static Future<dynamic> updateVariant(
    int id,
    int variantId,
    int stock,
    int price,
  ) async {
    final header = await ApiHeaders.getAuthHeaders();
    final uri = Uri.parse(
      ApiConfig.baseUrl + ApiConfig.productVariantUpdate(id, variantId),
    );
    final response = await http.put(
      uri,
      headers: header,
      body: jsonEncode({"price": price, "stock": stock}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to get variants');
    }
  }

  static Future<List<Option>> getOption(int id) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.options(id));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Option.fromJson(e)).toList();
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

  static Future<List<Rate>> getRate(int id) async {
    final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.getRate(id));
    final response = await http.get(uri);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((item) => Rate.fromJson(item))
          .toList();
    } else {
      throw Exception("Failed: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<bool> addProduct(ProductRegisterModel request) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.addNewProduct);
    print(request.descriptions);
    final multipartRequest = await request.toMultipartRequest(url);

    final header = await ApiHeaders.getAuthHeaders(); // sửa ở đây
    multipartRequest.headers.addAll(header);

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      debugPrint("Đăng ký sản phẩm thất bại: ${response.body}");
      return false;
    }
  }
}
