import 'dart:io';

import 'package:http/http.dart';

class ProductRegisterModel {
  final int ?id;
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
  

  ProductRegisterModel({
    required this.id,
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
  });

  


  Future<MultipartRequest> toMultipartRequest(Uri uri) async {
    final request = MultipartRequest('POST', uri);



    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category.toString();
    request.fields['min_price'] = minPrice.toString();
    request.fields['max_price'] = minPrice.toString();
    request.fields['province'] = province;
     request.fields['district'] = district;
    request.fields['ward'] = ward;
    request.fields['address'] = address;

    for (var img in uploadImages) {
      request.files.add(
        await MultipartFile.fromPath("upload_images", img.path),
      );
    }

    return request;
  }
}