class ProductModel {
  final int id;
  final String name;
  final String status;
  final String description;
  final int category;
  final double maxPrice;
  final double minPrice;
  final List<ProductImage> images;
  final String province;
  final String ward;
  final int soldQuantity;
  final OwnerModel owner;

  ProductModel({
    required this.id,
    required this.name,
    required this.status,
    required this.description,
    required this.category,
    required this.maxPrice,
    required this.minPrice,
    required this.images,
    required this.province,
    required this.ward,
    required this.soldQuantity,
    required this.owner,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      description: json['description'],
      category: json['category'],
      maxPrice: (json['max_price'] as num).toDouble(),
      minPrice: (json['min_price'] as num).toDouble(),
      images: (json['images'] as List)
          .map((img) => ProductImage.fromJson(img))
          .toList(),
      province: json['province'],
      ward: json['ward'],
      soldQuantity: json['sold_quantity'],
      owner: OwnerModel.fromJson(json['owner']),
    );
  }
}

class ProductImage {
  final int id;
  final String alt;
  final String image;

  ProductImage({
    required this.id,
    required this.alt,
    required this.image,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      alt: json['alt'],
      image: json['image'],
    );
  }
}

class OwnerModel {
  final int id;
  final String name;

  OwnerModel({
    required this.id,
    required this.name,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class CategoryModel {
  final int id;
  final String type;
  final String? descriptions;

  CategoryModel({
    required this.id,
    required this.type,
    this.descriptions,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      type: json['type'],
      descriptions: json['descriptions'],
    );
  }
}
