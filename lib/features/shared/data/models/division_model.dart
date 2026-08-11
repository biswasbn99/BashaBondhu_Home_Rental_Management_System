
class DivisionModel {
  const DivisionModel({
    required this.id,
    required this.name,
    required this.bnName,
  });

  final String id;
  final String name;
  final String bnName;

  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      bnName: (json['bn_name'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) => other is DivisionModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}