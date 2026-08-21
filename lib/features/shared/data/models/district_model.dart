
class DistrictModel {
  const DistrictModel({
    required this.id,
    required this.name,
    required this.bnName,
    this.divisionId,
    this.coordinates,
  });

  final String id;
  final String name;
  final String bnName;
  final String? divisionId;
  final String? coordinates;

  String getLocalizedName(String languageCode) => languageCode == 'bn' ? bnName : name;

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name_en'] ?? json['name'] ?? '').toString(),
      bnName: (json['name_bn'] ?? json['bn_name'] ?? json['name'] ?? '').toString(),
      divisionId: (json['division_id'] ?? json['divisionId'])?.toString(),
      coordinates: json['coordinates']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bn_name': bnName,
    'name_en': name,
    'name_bn': bnName,
    if (divisionId != null) 'division_id': divisionId,
    if (coordinates != null) 'coordinates': coordinates,
  };

  @override
  bool operator ==(Object other) => other is DistrictModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}