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
    Query query = _demandsCollection;
    if (tenantId.isNotEmpty) {
      query = query.where('tenantId', isEqualTo: tenantId);
    } else if (tenantEmail != null && tenantEmail.isNotEmpty) {
      query = query.where('tenantEmail', isEqualTo: tenantEmail);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TenantDemandModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    });
  }

  /// Stream all tenant demands for House Owners
  Stream<List<TenantDemandModel>> streamAllDemands() {
    return _demandsCollection
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TenantDemandModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    });
  }
}

