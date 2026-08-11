
class DistrictModel {
  const DistrictModel({
    required this.id,
    required this.name,
    required this.bnName,
    this.divisionId,
  });

  final String id;
  final String name;
  final String bnName;
  final String? divisionId;

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      bnName: (json['bn_name'] ?? '').toString(),
      divisionId: json['division_id']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) => other is DistrictModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}