import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/area_model.dart';
import '../models/sub_area_model.dart';

class FirestoreLocationService {
  FirestoreLocationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'locations';

  // In-memory cache: Division ID -> Map data (for ultra-fast 0ms cascading dropdown responses)
  final Map<String, Map<String, dynamic>> _divisionCache = {};
  List<DivisionModel>? _cachedDivisionsList;
  DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(hours: 1);

  /// Get all Divisions (Cached in-memory & Firestore local SQLite cache)
  Future<List<DivisionModel>> getDivisions({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedDivisionsList != null &&
        _cachedDivisionsList!.isNotEmpty &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheTtl) {
      return _cachedDivisionsList!;
    }

    try {
      final snapshot = await _firestore.collection(_collectionName).get(
            const GetOptions(source: Source.serverAndCache),
          );

      if (snapshot.docs.isNotEmpty) {
        _divisionCache.clear();
        final List<DivisionModel> list = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final id = doc.id.toLowerCase();
          _divisionCache[id] = data;
          list.add(DivisionModel.fromJson(data));
        }
        _cachedDivisionsList = list;
        _lastFetchTime = now;
        return list;
      }
    } catch (e) {
      debugPrint('Error fetching divisions from Firestore: $e');
    }

    return _cachedDivisionsList ?? [];
  }

  /// Realtime Stream of Divisions
  Stream<List<DivisionModel>> streamDivisions() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      final List<DivisionModel> list = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _divisionCache[doc.id.toLowerCase()] = data;
        list.add(DivisionModel.fromJson(data));
      }
      _cachedDivisionsList = list;
      return list;
    });
  }

  /// Get a single division's raw data (with cache)
  Future<Map<String, dynamic>?> _getDivisionData(String divisionId) async {
    final key = divisionId.toLowerCase();
    if (_divisionCache.containsKey(key)) {
      return _divisionCache[key];
    }

    try {
      final doc = await _firestore.collection(_collectionName).doc(key).get();
      if (doc.exists && doc.data() != null) {
        _divisionCache[key] = doc.data()!;
        return _divisionCache[key];
      }
    } catch (e) {
      debugPrint('Error fetching division $divisionId: $e');
    }

    // If not in cache by direct ID, ensure all divisions are loaded
    await getDivisions();
    return _divisionCache[key];
  }

  /// Get all Districts under a specific Division
  Future<List<DistrictModel>> getDistrictsByDivision(String divisionId) async {
    final divisionData = await _getDivisionData(divisionId);
    if (divisionData == null) return [];

    final districtsRaw = divisionData['districts'];
    if (districtsRaw is! List) return [];

    return districtsRaw.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      map['division_id'] = divisionId;
      return DistrictModel.fromJson(map);
    }).toList();
  }

  /// Get all Areas / Upazilas under a specific District
  Future<List<UpazilaModel>> getUpazilasByDistrict(String districtId) async {
    // Search cached divisions first
    if (_divisionCache.isEmpty) {
      await getDivisions();
    }

    for (final divisionData in _divisionCache.values) {
      final districtsRaw = divisionData['districts'];
      if (districtsRaw is List) {
        for (final district in districtsRaw) {
          if ((district['id']?.toString() ?? '').toLowerCase() == districtId.toLowerCase()) {
            final areasRaw = district['areas'];
            if (areasRaw is List) {
              return areasRaw.map((item) {
                final map = Map<String, dynamic>.from(item as Map);
                map['district_id'] = districtId;
                return UpazilaModel.fromJson(map);
              }).toList();
            }
          }
        }
      }
    }

    return [];
  }

  /// Get all Sub-Areas / Unions under a specific Area / Upazila
  Future<List<UnionModel>> getUnionsByUpazila(String upazilaId) async {
    if (_divisionCache.isEmpty) {
      await getDivisions();
    }

    for (final divisionData in _divisionCache.values) {
      final districtsRaw = divisionData['districts'];
      if (districtsRaw is List) {
        for (final district in districtsRaw) {
          final areasRaw = district['areas'];
          if (areasRaw is List) {
            for (final area in areasRaw) {
              if ((area['id']?.toString() ?? '').toLowerCase() == upazilaId.toLowerCase()) {
                final subAreasRaw = area['sub_areas'];
                if (subAreasRaw is List) {
                  return subAreasRaw.map((item) {
                    final map = Map<String, dynamic>.from(item as Map);
                    map['upazila_id'] = upazilaId;
                    return UnionModel.fromJson(map);
                  }).toList();
                }
              }
            }
          }
        }
      }
    }

    return [];
  }

  /// Update entire division document in Firestore (for Admin Management)
  Future<void> updateDivisionDocument(String divisionId, Map<String, dynamic> divisionData) async {
    final key = divisionId.toLowerCase();
    await _firestore.collection(_collectionName).doc(key).set(divisionData);
    _divisionCache[key] = divisionData;
    _lastFetchTime = DateTime.now();
  }

  /// Clear in-memory cache to force a re-fetch from Firestore
  void clearCache() {
    _divisionCache.clear();
    _cachedDivisionsList = null;
    _lastFetchTime = null;
  }
}
