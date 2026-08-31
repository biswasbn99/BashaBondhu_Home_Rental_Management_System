import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';

class TenantDemandFirestoreService {
  static final TenantDemandFirestoreService _instance =
      TenantDemandFirestoreService._internal();
  factory TenantDemandFirestoreService() => _instance;
  TenantDemandFirestoreService._internal();

  final CollectionReference _demandsCollection =
      FirebaseFirestore.instance.collection('tenant_demands');

  /// Create a new tenant demand document in Firestore
  Future<String> createDemand(TenantDemandModel demand) async {
    try {
      final docRef = _demandsCollection.doc();
      final finalDemand = demand.copyWith(id: docRef.id);
      await docRef.set(finalDemand.toMap());
      debugPrint('✅ Tenant demand created in Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating tenant demand: $e');
      rethrow;
    }
  }

  /// Update an existing tenant demand in Firestore
  Future<void> updateDemand(TenantDemandModel demand) async {
    try {
      await _demandsCollection.doc(demand.id).set(
            demand.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('✅ Tenant demand updated in Firestore: ${demand.id}');
    } catch (e) {
      debugPrint('❌ Error updating tenant demand: $e');
      rethrow;
    }
  }

  /// Delete a tenant demand document from Firestore
  Future<void> deleteDemand(String demandId) async {
    try {
      await _demandsCollection.doc(demandId).delete();
      debugPrint('🗑️ Tenant demand deleted from Firestore: $demandId');
    } catch (e) {
      debugPrint('❌ Error deleting tenant demand: $e');
      rethrow;
    }
  }

  /// Stream demands created by a specific tenant
  Stream<List<TenantDemandModel>> streamTenantDemands(
    String tenantId, {
    String? tenantEmail,
  }) {
    return _demandsCollection.snapshots().map((snapshot) {
      final List<TenantDemandModel> list = [];
      final String cleanId = tenantId.trim();
      final String cleanEmail = (tenantEmail ?? '').trim().toLowerCase();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final d = TenantDemandModel.fromMap(data, doc.id);
            final bool matchesId = cleanId.isNotEmpty && d.tenantId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && d.tenantEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(d);
            } else if (matchesId || matchesEmail) {
              list.add(d);
            }
          } else if (data is Map) {
            final d = TenantDemandModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            final bool matchesId = cleanId.isNotEmpty && d.tenantId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && d.tenantEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(d);
            } else if (matchesId || matchesEmail) {
              list.add(d);
            }
          }
        } catch (e) {
          debugPrint('Error parsing tenant demand doc ${doc.id}: $e');
        }
      }

      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    });
  }

  /// Stream all tenant demands for House Owners (only active/unfulfilled by default)
  Stream<List<TenantDemandModel>> streamAllDemands({bool onlyActive = true}) {
    return _demandsCollection.snapshots().map((snapshot) {
      final List<TenantDemandModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final d = TenantDemandModel.fromMap(data, doc.id);
            if (!onlyActive || !d.isFulfilled) {
              list.add(d);
            }
          } else if (data is Map) {
            final d = TenantDemandModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            if (!onlyActive || !d.isFulfilled) {
              list.add(d);
            }
          }
        } catch (e) {
          debugPrint('Error parsing tenant demand doc ${doc.id}: $e');
        }
      }

      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    });
  }

  /// Toggle demand fulfilled status (isFulfilled = true/false)
  Future<void> toggleDemandFulfilledStatus(String demandId, bool isFulfilled) async {
    try {
      await _demandsCollection.doc(demandId).set({
        'isFulfilled': isFulfilled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Tenant demand fulfilled status updated: $demandId -> isFulfilled: $isFulfilled');
    } catch (e) {
      debugPrint('❌ Error toggling demand fulfilled status: $e');
      rethrow;
    }
  }

  /// Get all tenant demands (Future)
  Future<List<TenantDemandModel>> getAllDemands() async {
    try {
      final snapshot = await _demandsCollection.get();
      final List<TenantDemandModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            list.add(TenantDemandModel.fromMap(data, doc.id));
          } else if (data is Map) {
            list.add(TenantDemandModel.fromMap(Map<String, dynamic>.from(data), doc.id));
          }
        } catch (e) {
          debugPrint('Error parsing tenant demand doc ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    } catch (e) {
      debugPrint('Error getting all tenant demands: $e');
      return [];
    }
  }

  /// Get demands for a specific tenant (Future)
  Future<List<TenantDemandModel>> getTenantDemands(String tenantId, {String? tenantEmail}) async {
    try {
      final snapshot = await _demandsCollection.get();
      final List<TenantDemandModel> list = [];
      final String cleanId = tenantId.trim();
      final String cleanEmail = (tenantEmail ?? '').trim().toLowerCase();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final d = TenantDemandModel.fromMap(data, doc.id);
            final bool matchesId = cleanId.isNotEmpty && d.tenantId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && d.tenantEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(d);
            } else if (matchesId || matchesEmail) {
              list.add(d);
            }
          } else if (data is Map) {
            final d = TenantDemandModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            final bool matchesId = cleanId.isNotEmpty && d.tenantId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && d.tenantEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(d);
            } else if (matchesId || matchesEmail) {
              list.add(d);
            }
          }
        } catch (e) {
          debugPrint('Error parsing tenant demand doc ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    } catch (e) {
      debugPrint('Error getting tenant demands: $e');
      return [];
    }
  }
}

