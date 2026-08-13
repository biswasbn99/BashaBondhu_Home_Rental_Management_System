import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/area_model.dart';
import '../models/sub_area_model.dart';


class LocationApiService {
  LocationApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'https://bdapis.vercel.app/geo/v2.0';

  Future<List<DivisionModel>> getDivisions() async {
    final data = await _getList('$baseUrl/divisions');
    return data.map(DivisionModel.fromJson).toList();
  }

  Future<List<DistrictModel>> getDistrictsByDivision(String divisionId) async {
    final data = await _getList('$baseUrl/districts/$divisionId');
    return data.map(DistrictModel.fromJson).toList();
  }

  Future<List<UpazilaModel>> getUpazilasByDistrict(String districtId) async {
    final data = await _getList('$baseUrl/upazilas/$districtId');
    return data.map(UpazilaModel.fromJson).toList();
  }

  Future<List<UnionModel>> getUnionsByUpazila(String upazilaId) async {
    final data = await _getList('$baseUrl/unions/$upazilaId');
    return data.map(UnionModel.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _getList(String url) async {
    final response = await _client
        .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    // The API returns 404 with an empty `data` array when a division/
    // district genuinely has no children yet — treat that as "no results"
    // rather than an error.
    if (response.statusCode == 404) {
      return const [];
    }

    if (response.statusCode != 200) {
      throw LocationApiException(
        'Request failed (${response.statusCode}) for $url',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const LocationApiException('Unexpected response shape');
    }

    if (decoded['success'] != true) {
      throw LocationApiException(
        (decoded['message'] ?? 'Request was not successful').toString(),
      );
    }

    final list = decoded['data'];
    if (list is! List) return const [];

    return list.cast<Map<String, dynamic>>();
  }

  void dispose() => _client.close();
}

class LocationApiException implements Exception {
  const LocationApiException(this.message);
  final String message;

  @override
  String toString() => message;
}