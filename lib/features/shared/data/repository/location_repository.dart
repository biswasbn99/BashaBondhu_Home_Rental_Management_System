import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/area_model.dart';
import '../models/sub_area_model.dart';
import '../services/firestore_location_service.dart';

class LocationRepository {
  LocationRepository({FirestoreLocationService? locationService})
      : _locationService = locationService ?? FirestoreLocationService();

  final FirestoreLocationService _locationService;

  Future<List<DivisionModel>> getDivisions({bool forceRefresh = false}) {
    return _locationService.getDivisions(forceRefresh: forceRefresh);
  }

  Stream<List<DivisionModel>> streamDivisions() {
    return _locationService.streamDivisions();
  }

  Future<List<DistrictModel>> getDistrictsByDivision(String divisionId) {
    return _locationService.getDistrictsByDivision(divisionId);
  }

  Future<List<UpazilaModel>> getUpazilasByDistrict(String districtId) {
    return _locationService.getUpazilasByDistrict(districtId);
  }

  Future<List<UnionModel>> getUnionsByUpazila(String upazilaId) {
    return _locationService.getUnionsByUpazila(upazilaId);
  }

  Future<void> updateDivisionDocument(String divisionId, Map<String, dynamic> divisionData) {
    return _locationService.updateDivisionDocument(divisionId, divisionData);
  }

  void clearCache() {
    _locationService.clearCache();
  }
}