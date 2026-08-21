class UnionModel {
  const UnionModel({
    required this.id,
    required this.name,
    required this.bnName,
    this.upazilaId,
    this.coordinates,
  });

  final String id;
  final String name;
  final String bnName;
  final String? upazilaId;
  final String? coordinates;

  String getLocalizedName(String languageCode) => languageCode == 'bn' ? bnName : name;

  factory UnionModel.fromJson(Map<String, dynamic> json) {
    return UnionModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name_en'] ?? json['name'] ?? '').toString(),
      bnName: (json['name_bn'] ?? json['bn_name'] ?? json['name'] ?? '').toString(),
      upazilaId: (json['upazila_id'] ?? json['upazilaId'] ?? json['area_id'])?.toString(),
      coordinates: json['coordinates']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bn_name': bnName,
    'name_en': name,
    'name_bn': bnName,
    if (upazilaId != null) 'upazila_id': upazilaId,
    if (coordinates != null) 'coordinates': coordinates,
  };

  @override
  bool operator ==(Object other) => other is UnionModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
