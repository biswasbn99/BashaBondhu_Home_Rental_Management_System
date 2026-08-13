import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/area_model.dart';
import '../models/sub_area_model.dart';
import '../services/location_api_service.dart';


class LocationRepository {
  LocationRepository({LocationApiService? apiService})
      : _apiService = apiService ?? LocationApiService();

  final LocationApiService _apiService;

  Future<List<DivisionModel>> getDivisions() {
    return _apiService.getDivisions();
  }

  Future<List<DistrictModel>> getDistrictsByDivision(String divisionId) {
    return _apiService.getDistrictsByDivision(divisionId);
  }

  Future<List<UpazilaModel>> getUpazilasByDistrict(String districtId) {
    return _apiService.getUpazilasByDistrict(districtId);
  }

  Future<List<UnionModel>> getUnionsByUpazila(String upazilaId) {
    return _apiService.getUnionsByUpazila(upazilaId);
  }
}