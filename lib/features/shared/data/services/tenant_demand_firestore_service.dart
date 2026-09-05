import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import '../models/app_notification_model.dart';
import 'notification_firestore_service.dart';

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
      // Check Auto-Approval setting from Firestore
      bool autoApprove = true;
      try {
        final settingsDoc = await FirebaseFirestore.instance.collection('app_settings').doc('general').get();
        if (settingsDoc.exists && settingsDoc.data() != null) {
          autoApprove = (settingsDoc.data()!['autoApprovalEnabled'] as bool?) ?? true;
        }
      } catch (_) {}

      final docRef = _demandsCollection.doc();
      final finalDemand = demand.copyWith(
        id: docRef.id,
        approvalStatus: autoApprove ? 'approved' : 'pending',
        approvedAt: autoApprove ? DateTime.now() : null,
      );
      await docRef.set(finalDemand.toMap());
      debugPrint('✅ Tenant demand created in Firestore: ${docRef.id} (AutoApproved: $autoApprove)');

      // Dispatch Notification to Admin
      try {
        final houseTypeName = demand.houseType.name;
        final locationStr = "${demand.area.name}, ${demand.district.name}";
        final budgetStr = demand.budgetRange != null && demand.budgetRange!.isNotEmpty
            ? "৳${demand.budgetRange}"
            : "Negotiable";
        final posterName = demand.userName.isNotEmpty
            ? demand.userName
            : demand.tenantEmail.split('@').first;

        await NotificationFirestoreService().createNotification(
          AppNotificationModel(
            id: '',
            recipientType: 'admin',
            recipientId: 'admin',
            recipientEmail: demand.tenantEmail,
            title: 'New Tenant Demand Added',
            titleBn: 'নতুন ভাড়াটিয়া চাহিদা পোস্ট',
            message: 'Tenant $posterName (${demand.tenantEmail}) posted a demand for $houseTypeName in $locationStr (Budget: $budgetStr). Status: ${autoApprove ? 'Auto-Approved' : 'Pending Review'}.',
            messageBn: 'ভাড়াটিয়া $posterName (${demand.tenantEmail}) নতুন চাহিদা পোস্ট দিয়েছেন: $houseTypeName ($locationStr, বাজেট: $budgetStr)। স্ট্যাটাস: ${autoApprove ? 'স্বয়ংক্রিয় অনুমোদিত' : 'পেন্ডিং'}।',
            type: 'post_created',
            targetType: 'demand',
            targetId: docRef.id,
            data: {
              'demandId': docRef.id,
              'postTitle': '$houseTypeName ($locationStr)',
              'budget': demand.budgetRange ?? '',
              'location': locationStr,
              'tenantEmail': demand.tenantEmail,
              'userName': posterName,
              'tenantId': demand.tenantId,
              'approvalStatus': autoApprove ? 'approved' : 'pending',
              'category': 'Demand',
            },
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Error sending admin notification on demand create: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating tenant demand: $e');
      rethrow;
    }
  }

  /// Update an existing tenant demand in Firestore
  Future<void> updateDemand(TenantDemandModel demand) async {
    try {
      // Check Auto-Approval setting from Firestore
      bool autoApprove = true;
      try {
        final settingsDoc = await FirebaseFirestore.instance.collection('app_settings').doc('general').get();
        if (settingsDoc.exists && settingsDoc.data() != null) {
          autoApprove = (settingsDoc.data()!['autoApprovalEnabled'] as bool?) ?? true;
        }
      } catch (_) {}

      // If autoApprove is false OR post was rejected, reset to pending for review
      final bool shouldBePending = !autoApprove || demand.approvalStatus == 'rejected';
      final updatedDemand = demand.copyWith(
        approvalStatus: shouldBePending ? 'pending' : demand.approvalStatus,
        rejectionReason: '',
      );

      await _demandsCollection.doc(demand.id).set(
            updatedDemand.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('✅ Tenant demand updated in Firestore: ${demand.id} (status: ${updatedDemand.approvalStatus})');

      // Dispatch Notification to Admin
      try {
        final houseTypeName = demand.houseType.name;
        final locationStr = "${demand.area.name}, ${demand.district.name}";
        final budgetStr = demand.budgetRange != null && demand.budgetRange!.isNotEmpty
            ? "৳${demand.budgetRange}"
            : "Negotiable";
        final posterName = demand.userName.isNotEmpty
            ? demand.userName
            : demand.tenantEmail.split('@').first;

        await NotificationFirestoreService().createNotification(
          AppNotificationModel(
            id: '',
            recipientType: 'admin',
            recipientId: 'admin',
            recipientEmail: demand.tenantEmail,
            title: 'Tenant Demand Updated & Resubmitted',
            titleBn: 'ভাড়াটিয়া চাহিদা সংশোধন ও পুনরায় জমা',
            message: 'Tenant $posterName (${demand.tenantEmail}) updated and resubmitted demand for $houseTypeName in $locationStr (Budget: $budgetStr). Please review.',
            messageBn: 'ভাড়াটিয়া $posterName (${demand.tenantEmail}) চাহিদা পোস্ট ($houseTypeName - $locationStr, বাজেট: $budgetStr) সংশোধন করে পুনরায় পর্যালোচনার জন্য জমা দিয়েছেন। অনুগ্রহ করে রিভিউ করুন।',
            type: 'post_updated',
            targetType: 'demand',
            targetId: demand.id,
            data: {
              'demandId': demand.id,
              'postTitle': '$houseTypeName ($locationStr)',
              'budget': demand.budgetRange ?? '',
              'location': locationStr,
              'tenantEmail': demand.tenantEmail,
              'userName': posterName,
              'tenantId': demand.tenantId,
              'approvalStatus': shouldBePending ? 'pending' : demand.approvalStatus,
              'category': 'Demand',
            },
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Error sending admin notification on demand update: $e');
      }
    } catch (e) {
      debugPrint('❌ Error updating tenant demand: $e');
      rethrow;
    }
  }

  /// Delete a tenant demand document from Firestore
  Future<void> deleteDemand(String demandId) async {
    try {
      // Fetch details before delete
      String postTitle = 'Demand #$demandId';
      String tenantEmail = '';
      String userName = '';
      try {
        final snap = await _demandsCollection.doc(demandId).get();
        if (snap.exists && snap.data() != null) {
          final data = Map<String, dynamic>.from(snap.data() as Map);
          postTitle = "${data['houseType'] ?? 'Demand'} (${data['month'] ?? ''})";
          tenantEmail = data['tenantEmail'] ?? '';
          userName = data['userName'] ?? '';
        }
      } catch (_) {}

      await _demandsCollection.doc(demandId).delete();
      debugPrint('🗑️ Tenant demand deleted from Firestore: $demandId');

      // Dispatch Notification to Admin
      try {
        await NotificationFirestoreService().createNotification(
          AppNotificationModel(
            id: '',
            recipientType: 'admin',
            recipientId: 'admin',
            recipientEmail: tenantEmail,
            title: 'Tenant Demand Deleted',
            titleBn: 'ভাড়াটিয়া চাহিদা মুছে ফেলা হয়েছে',
            message: 'Demand post "$postTitle" ($demandId) was deleted by tenant.',
            messageBn: 'ভাড়াটিয়া চাহিদা পোস্ট "$postTitle" ($demandId) মুছে ফেলা হয়েছে।',
            type: 'post_deleted',
            targetType: 'demand',
            targetId: demandId,
            data: {
              'demandId': demandId,
              'postTitle': postTitle,
              'tenantEmail': tenantEmail,
              'userName': userName,
              'category': 'Demand',
            },
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Error sending admin notification on demand delete: $e');
      }
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

  /// Stream all tenant demands for House Owners (only approved and active by default)
  Stream<List<TenantDemandModel>> streamAllDemands({bool onlyActive = true}) {
    return _demandsCollection.snapshots().map((snapshot) {
      final List<TenantDemandModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final d = TenantDemandModel.fromMap(data, doc.id);
            final bool isLive = !d.isFulfilled && d.approvalStatus == 'approved';
            if (!onlyActive || isLive) {
              list.add(d);
            }
          } else if (data is Map) {
            final d = TenantDemandModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            final bool isLive = !d.isFulfilled && d.approvalStatus == 'approved';
            if (!onlyActive || isLive) {
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

