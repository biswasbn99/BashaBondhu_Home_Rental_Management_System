
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
      id: (json['id'] ?? '').toString(),
      name: (json['name_en'] ?? json['name'] ?? '').toString(),
      bnName: (json['name_bn'] ?? json['bn_name'] ?? json['name'] ?? '').toString(),
      districtId: (json['district_id'] ?? json['districtId'])?.toString(),
      coordinates: json['coordinates']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bn_name': bnName,
    'name_en': name,
    'name_bn': bnName,
    if (districtId != null) 'district_id': districtId,
    if (coordinates != null) 'coordinates': coordinates,
  };

  @override
  bool operator ==(Object other) => other is UpazilaModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}