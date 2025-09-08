import 'package:frontend/features/location/models/location_model.dart';

class ProductDetailModel {
  final int id;
  final String name;
  final String status;
  final String description;
  final Owner owner;
  final String category;
  final PriceRange priceRange;
  final List<ProductImage> images;
  final Location location;
  final List<ProductVariant> variants;
  final List<Option> options;
  final int soldQuantity;

  ProductDetailModel({
    required this.id,
    required this.name,
    required this.status,
    required this.description,
    required this.owner,
    required this.category,
    required this.priceRange,
    required this.images,
    required this.location,
    required this.variants,
    required this.options,
    required this.soldQuantity,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      description: json['description'] ?? "",
      owner: Owner.fromJson(json['owner']),
      category: json['category'],
      priceRange: PriceRange.fromJson(json['price_range']),
      images: (json['images'] as List? ?? [])
          .map((e) => ProductImage.fromJson(e))
          .toList(),
      location: Location.fromJson(json['location']),
      variants: (json['variants'] as List? ?? [])
          .map((e) => ProductVariant.fromJson(e))
          .toList(),
      options: (json['options'] as List? ?? [])
          .map((e) => Option.fromJson(e))
          .toList(),
      soldQuantity: json['sold_quantity'] ?? 0,
    );
  }
}

// Owner
class Owner {
  final int id;
  final String name;

  Owner({required this.id, required this.name});

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(id: json['id'], name: json['name']);
  }
}

// Price Range
class PriceRange {
  final double min;
  final double max;

  PriceRange({required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }
}

// Location
class Location {
  final String? province;
  final String? ward;

  Location({this.province, this.ward});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(province: json['province'], ward: json['ward']);
  }
}

// Product Image
class ProductImage {
  final int id;
  final String alt;
  final String image;

  ProductImage({required this.id, required this.alt, required this.image});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(id: json['id'], alt: json['alt'], image: json['image']);
  }
}

// Variant
class ProductVariant {
  final int id;
  double price; // bỏ final
  int stock; 
  final VariantProduct? product;
  final List<OptionValue> optionValues;

  ProductVariant({
    required this.id,
    required this.price,
    required this.stock,
    this.product,
    required this.optionValues,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      product: json['product'] != null
          ? VariantProduct.fromJson(json['product'])
          : null,
      optionValues: (json['option_values'] as List? ?? [])
          .map((e) => OptionValue.fromJson(e))
          .toList(),
    );
  }
}

class VariantProduct {
  final int id;
  final String name;
  final String image;
  final Province? province;

  VariantProduct({
    required this.id,
    required this.name,
    required this.image,
    this.province,
  });

  factory VariantProduct.fromJson(Map<String, dynamic> json) {
    return VariantProduct(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      province: json['province'] != null
          ? Province.fromJson(json['province'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image,
        "province": province?.toJson(),
      };
}

// Option & OptionValue
class Option {
  final int id;
  final String type;
  final List<OptionValue> optionValues;

  Option({required this.id, required this.type, required this.optionValues});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      type: json['type'],
      optionValues: (json['option_value'] as List? ?? [])
          .map((e) => OptionValue.fromJson(e))
          .toList(),
    );
  }
}

class OptionValue {
  final int id;
  final String value;
  final OptionType option;

  OptionValue({required this.id, required this.value, required this.option});

  factory OptionValue.fromJson(Map<String, dynamic> json) {
    return OptionValue(
      id: json['id'],
      value: json['value'],
      option: OptionType.fromJson(json['option']),
    );
  }
}

class OptionType {
  final String type;

  OptionType({required this.type});

  factory OptionType.fromJson(Map<String, dynamic> json) {
    return OptionType(type: json['type']);
  }
}

class Rate {
  final int id;
  final double rate;
  final String content;
  final String ownerName;
  final int orderId;
  final DateTime createdAt;

  Rate({
    required this.id,
    required this.rate,
    required this.content,
    required this.ownerName,
    required this.orderId,
    required this.createdAt,
  });

  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      id: json['id'],
      rate: (json['rate'] as num).toDouble(),
      content: json['content'],
      ownerName: json['owner_name'],
      orderId: json['order_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
