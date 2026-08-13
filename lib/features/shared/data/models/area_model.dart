
class UpazilaModel {
  const UpazilaModel({
    required this.id,
    required this.name,
    required this.bnName,
    this.districtId,
    this.coordinates,
  });

  final String id;
  final String name;
  final String bnName;
  final String? districtId;
  final String? coordinates;

  String getLocalizedName(String languageCode) => languageCode == 'bn' ? bnName : name;

  factory UpazilaModel.fromJson(Map<String, dynamic> json) {
    return UpazilaModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      bnName: (json['bn_name'] ?? '').toString(),
      districtId: json['district_id']?.toString(),
      coordinates: json['coordinates']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) => other is UpazilaModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}