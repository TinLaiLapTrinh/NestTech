class OptionModel {
  String type;
  List<String> values;
  int imageRequire;

  OptionModel({
    required this.type,
    required this.values,
    required this.imageRequire,
  });

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "values": values,
      "image_require": imageRequire,
    };
  }
}
