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
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      bnName: (json['bn_name'] ?? '').toString(),
      upazilaId: json['upazila_id']?.toString(),
      coordinates: json['coordinates']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) => other is UnionModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
