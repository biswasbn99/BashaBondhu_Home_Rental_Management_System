
class DivisionModel {
  const DivisionModel({
    required this.id,
    required this.name,
    required this.bnName,
    this.coordinates,
  });

  final String id;
  final String name;
  final String bnName;
  final String? coordinates;

  String getLocalizedName(String languageCode) => languageCode == 'bn' ? bnName : name;

  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name_en'] ?? json['name'] ?? '').toString(),
      bnName: (json['name_bn'] ?? json['bn_name'] ?? json['name'] ?? '').toString(),
      coordinates: json['coordinates']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bn_name': bnName,
    'name_en': name,
    'name_bn': bnName,
    if (coordinates != null) 'coordinates': coordinates,
  };

  @override
  bool operator ==(Object other) => other is DivisionModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}