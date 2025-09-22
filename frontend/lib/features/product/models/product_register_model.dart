import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

class ProductRegisterModel {
  final int? id;
  final String name;
  final String description;
  final int category;
  final double maxPrice;
  final double minPrice;
  final List<File> uploadImages;
  final String province;
  final String district;
  final String ward;
  final String address;
  final List<DescriptionItem> descriptions; // ✅ đổi sang class riêng

  ProductRegisterModel({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.maxPrice,
    required this.minPrice,
    required this.uploadImages,
    required this.province,
    required this.district,
    required this.ward,
    required this.address,
    required this.descriptions,
  });

  Future<MultipartRequest> toMultipartRequest(Uri uri) async {
    final request = MultipartRequest('POST', uri);

    // Trường text cơ bản
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category.toString();
    request.fields['min_price'] = minPrice.toString();
    request.fields['max_price'] = maxPrice.toString();
    request.fields['province'] = province;
    request.fields['district'] = district;
    request.fields['ward'] = ward;
    request.fields['address'] = address;

    // ✅ gửi descriptions
    request.fields['description_product'] = jsonEncode(
      descriptions.map((e) => e.toJson()).toList(),
    );

    // ✅ Thêm file ảnh
    for (var img in uploadImages) {
      request.files.add(
        await MultipartFile.fromPath("upload_images", img.path),
      );
    }

    return request;
  }
}

class DescriptionItem {
  final String title;
  final String content;

  DescriptionItem({required this.title, required this.content});

  factory DescriptionItem.fromJson(Map<String, dynamic> json) {
    return DescriptionItem(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, String> toJson() => {
    "title": title, 
    "content": content
  };

  // Thêm phương thức kiểm tra validation
  bool get isValid => title.isNotEmpty && content.isNotEmpty;
  
  // Thêm phương thức copyWith để cập nhật giá trị
  DescriptionItem copyWith({String? title, String? content}) {
    return DescriptionItem(
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}