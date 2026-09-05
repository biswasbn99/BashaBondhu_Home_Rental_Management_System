import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';
import '../../../shared/data/models/app_notification_model.dart';
import '../../../shared/data/services/notification_firestore_service.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';

class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _propertiesCollection => _firestore.collection('properties');
  CollectionReference get _demandsCollection => _firestore.collection('tenant_demands');
  CollectionReference get _reportsCollection => _firestore.collection('reports');
  CollectionReference get _categoriesCollection => _firestore.collection('categories');
  CollectionReference get _faqsCollection => _firestore.collection('faqs');
  DocumentReference get _settingsDoc => _firestore.collection('app_settings').doc('general');

  // ==========================================================================
  // 1. USER MANAGEMENT
  // ==========================================================================

  Stream<List<UserModel>> streamAllUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      final List<UserModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final map = Map<String, dynamic>.from(data);
            if (!map.containsKey('uid') || (map['uid'] as String).isEmpty) {
              map['uid'] = doc.id;
            }
            list.add(UserModel.fromMap(map));
          } else if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            if (!map.containsKey('uid') || (map['uid'] as String).isEmpty) {
              map['uid'] = doc.id;
            }
            list.add(UserModel.fromMap(map));
          }
        } catch (e) {
          debugPrint('Error parsing user doc ${doc.id}: $e');
        }
      }
      return list;
    });
  }

  Future<void> updateUserBlockStatus(String uid, bool isBlocked, {String? reason}) async {
    final Map<String, dynamic> updateData = {
      'isBlocked': isBlocked,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isBlocked) {
      updateData['blockReason'] = (reason != null && reason.trim().isNotEmpty)
          ? reason.trim()
          : 'Account suspended due to policy violation';
      updateData['blockedAt'] = DateTime.now().toIso8601String();
      updateData['appealStatus'] = 'none';
      updateData['appealFeedback'] = '';
    } else {
      updateData['blockReason'] = '';
      updateData['appealStatus'] = 'approved';
    }
    await _usersCollection.doc(uid).set(updateData, SetOptions(merge: true));
  }

  Future<void> submitUserAppeal(String uid, {required String note, required String contact}) async {
    await _usersCollection.doc(uid).set({
      'appealStatus': 'pending',
      'appealNote': note.trim(),
      'appealContact': contact.trim(),
      'appealAt': DateTime.now().toIso8601String(),
      'appealFeedback': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resolveUserAppeal(String uid, {required bool approve, String? adminFeedback}) async {
    final Map<String, dynamic> updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (approve) {
      updateData['isBlocked'] = false;
      updateData['blockReason'] = '';
      updateData['appealStatus'] = 'approved';
      updateData['appealFeedback'] = (adminFeedback != null && adminFeedback.trim().isNotEmpty)
          ? adminFeedback.trim()
          : 'Appeal approved by administration. Account restored.';
    } else {
      updateData['isBlocked'] = true;
      updateData['appealStatus'] = 'rejected';
      updateData['appealFeedback'] = (adminFeedback != null && adminFeedback.trim().isNotEmpty)
          ? adminFeedback.trim()
          : 'Appeal rejected after review.';
    }
    await _usersCollection.doc(uid).set(updateData, SetOptions(merge: true));
  }

  Future<void> updateUserNidStatus(String uid, String status, {String? reason}) async {
    final bool isVerified = status.toLowerCase() == 'verified';
    final Map<String, dynamic> updateData = {
      'nidVerificationStatus': status, // 'verified', 'unverified', 'pending', 'rejected'
      'verificationStatus': status,
      'isVerified': isVerified,
      'nidVerificationDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reason != null && reason.isNotEmpty) {
      updateData['nidRejectionReason'] = reason;
      updateData['verificationFeedback'] = reason;
    } else if (isVerified || status == 'unverified') {
      updateData['nidRejectionReason'] = '';
      updateData['verificationFeedback'] = '';
    }
    await _usersCollection.doc(uid).set(updateData, SetOptions(merge: true));
  }

  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }

  // ==========================================================================
  // 2. PROPERTY MANAGEMENT
  // ==========================================================================

  Stream<List<PropertyModel>> streamAllProperties() {
    return _propertiesCollection
        .orderBy('postDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<PropertyModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            list.add(PropertyModel.fromMap(data, doc.id));
          } else if (data is Map) {
            list.add(PropertyModel.fromMap(Map<String, dynamic>.from(data), doc.id));
          }
        } catch (e) {
          debugPrint('Error parsing property doc ${doc.id}: $e');
        }
      }
      return list;
    });
  }

  Future<void> updatePropertyApproval(String propertyId, String status, {String? reason}) async {
    final bool isApproved = status == 'approved';
    final Map<String, dynamic> updateData = {
      'approvalStatus': status, // 'approved', 'pending', 'rejected'
      'isApproved': isApproved,
      'isAvailable': isApproved,
      'approvalDate': FieldValue.serverTimestamp(),
      'approvedAt': isApproved ? DateTime.now().toIso8601String() : null,
    };
    if (reason != null && reason.isNotEmpty) {
      updateData['rejectionReason'] = reason;
    } else if (isApproved) {
      updateData['rejectionReason'] = '';
    }
    await _propertiesCollection.doc(propertyId).set(updateData, SetOptions(merge: true));

    // Send Notification to House Owner
    try {
      final docSnap = await _propertiesCollection.doc(propertyId).get();
      if (docSnap.exists && docSnap.data() != null) {
        final data = Map<String, dynamic>.from(docSnap.data() as Map);
        final ownerId = (data['ownerId'] as String? ?? '').trim();
        final ownerEmail = (data['ownerEmail'] as String? ?? '').trim();
        final postTitle = (data['shortAddress'] as String? ?? '').isNotEmpty
            ? data['shortAddress'] as String
            : (data['houseType'] as String? ?? 'Property');

        if (status == 'rejected') {
          final rejectMsg = (reason != null && reason.trim().isNotEmpty)
              ? reason.trim()
              : 'Does not comply with community guidelines';
          await NotificationFirestoreService().createNotification(
            AppNotificationModel(
              id: '',
              recipientType: 'user',
              recipientId: ownerId,
              recipientEmail: ownerEmail,
              title: 'Post Rejected by Admin',
              titleBn: 'আপনার বিজ্ঞাপনটি প্রত্যাখ্যান করা হয়েছে',
              message: 'Your property listing "$postTitle" was rejected. Reason: $rejectMsg. Please edit and resubmit.',
              messageBn: 'আপনার বাড়িভাড়া বিজ্ঞাপন "$postTitle" অ্যাডমিন কর্তৃক প্রত্যাখ্যাত হয়েছে। কারণ: $rejectMsg। অনুগ্রহ করে বিজ্ঞাপনটি সংশোধন করে পুনরায় জমা দিন।',
              type: 'post_rejected',
              targetType: 'property',
              targetId: propertyId,
              data: {
                'propertyId': propertyId,
                'postTitle': postTitle,
                'rejectionReason': rejectMsg,
                'amount': data['amount'] ?? '',
                'category': 'Listing',
              },
              createdAt: DateTime.now(),
            ),
          );
        } else if (status == 'approved') {
          await NotificationFirestoreService().createNotification(
            AppNotificationModel(
              id: '',
              recipientType: 'user',
              recipientId: ownerId,
              recipientEmail: ownerEmail,
              title: 'Property Listing Approved!',
              titleBn: 'বাড়িভাড়া বিজ্ঞাপন অনুমোদিত হয়েছে!',
              message: 'Your property listing "$postTitle" has been approved by admin and is now live.',
              messageBn: 'আপনার বাড়িভাড়া বিজ্ঞাপন "$postTitle" অ্যাডমিন কর্তৃক অনুমোদিত হয়েছে এবং এটি এখন লাইভ।',
              type: 'post_approved',
              targetType: 'property',
              targetId: propertyId,
              data: {
                'propertyId': propertyId,
                'postTitle': postTitle,
                'amount': data['amount'] ?? '',
                'category': 'Listing',
              },
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending property notification: $e');
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    await _propertiesCollection.doc(propertyId).delete();
  }

  // ==========================================================================
  // 2.1 TENANT DEMAND MANAGEMENT
  // ==========================================================================

  Stream<List<TenantDemandModel>> streamAllDemands() {
    return _demandsCollection
        .orderBy('postDate', descending: true)
        .snapshots()
        .map((snapshot) {
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
          debugPrint('Error parsing demand doc ${doc.id}: $e');
        }
      }
      return list;
    });
  }

  Future<void> updateDemandApproval(String demandId, String status, {String? reason}) async {
    final bool isApproved = status == 'approved';
    final Map<String, dynamic> updateData = {
      'approvalStatus': status, // 'approved', 'pending', 'rejected'
      'isApproved': isApproved,
      'approvalDate': FieldValue.serverTimestamp(),
      'approvedAt': isApproved ? DateTime.now().toIso8601String() : null,
    };
    if (reason != null && reason.isNotEmpty) {
      updateData['rejectionReason'] = reason;
    } else if (isApproved) {
      updateData['rejectionReason'] = '';
    }
    await _demandsCollection.doc(demandId).set(updateData, SetOptions(merge: true));

    // Send Notification to Tenant
    try {
      final docSnap = await _demandsCollection.doc(demandId).get();
      if (docSnap.exists && docSnap.data() != null) {
        final data = Map<String, dynamic>.from(docSnap.data() as Map);
        final tenantId = (data['tenantId'] as String? ?? '').trim();
        final tenantEmail = (data['tenantEmail'] as String? ?? '').trim();
        final houseTypeName = (data['houseType'] as String? ?? 'Demand');
        final monthName = (data['month'] as String? ?? '');
        final postTitle = '$houseTypeName ($monthName)';

        if (status == 'rejected') {
          final rejectMsg = (reason != null && reason.trim().isNotEmpty)
              ? reason.trim()
              : 'Does not comply with community guidelines';
          await NotificationFirestoreService().createNotification(
            AppNotificationModel(
              id: '',
              recipientType: 'user',
              recipientId: tenantId,
              recipientEmail: tenantEmail,
              title: 'Demand Post Rejected by Admin',
              titleBn: 'আপনার চাহিদা পোস্টটি প্রত্যাখ্যান করা হয়েছে',
              message: 'Your demand post "$postTitle" was rejected. Reason: $rejectMsg. Please edit and resubmit.',
              messageBn: 'আপনার ভাড়াটিয়া চাহিদা পোস্ট "$postTitle" অ্যাডমিন কর্তৃক প্রত্যাখ্যাত হয়েছে। কারণ: $rejectMsg। অনুগ্রহ করে চাহিদাটি সংশোধন করে পুনরায় জমা দিন।',
              type: 'post_rejected',
              targetType: 'demand',
              targetId: demandId,
              data: {
                'demandId': demandId,
                'postTitle': postTitle,
                'rejectionReason': rejectMsg,
                'budget': data['budgetRange'] ?? '',
                'category': 'Demand',
              },
              createdAt: DateTime.now(),
            ),
          );
        } else if (status == 'approved') {
          await NotificationFirestoreService().createNotification(
            AppNotificationModel(
              id: '',
              recipientType: 'user',
              recipientId: tenantId,
              recipientEmail: tenantEmail,
              title: 'Tenant Demand Approved!',
              titleBn: 'ভাড়াটিয়া চাহিদা অনুমোদিত হয়েছে!',
              message: 'Your demand post "$postTitle" has been approved by admin and is now visible to house owners.',
              messageBn: 'আপনার ভাড়াটিয়া চাহিদা পোস্ট "$postTitle" অনুমোদিত হয়েছে এবং বাড়িওয়ালারা এটি এখন দেখতে পাবেন।',
              type: 'post_approved',
              targetType: 'demand',
              targetId: demandId,
              data: {
                'demandId': demandId,
                'postTitle': postTitle,
                'budget': data['budgetRange'] ?? '',
                'category': 'Demand',
              },
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending demand notification: $e');
    }
  }

  Future<void> deleteDemand(String demandId) async {
    await _demandsCollection.doc(demandId).delete();
  }

  // ==========================================================================
  // 3. REPORTS MANAGEMENT
  // ==========================================================================

  Stream<List<Map<String, dynamic>>> streamReports() {
    return _reportsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> createReport(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['status'] = data['status'] ?? 'pending';
    await _reportsCollection.add(data);
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _reportsCollection.doc(reportId).set({
      'status': status, // 'pending', 'reviewed', 'resolved'
      'resolvedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteReport(String reportId) async {
    await _reportsCollection.doc(reportId).delete();
  }

  // ==========================================================================
  // 4. CATEGORY MANAGEMENT
  // ==========================================================================

  Stream<List<Map<String, dynamic>>> streamCategories() {
    return _categoriesCollection.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        _seedDefaultCategories();
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await _categoriesCollection.add(data);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _categoriesCollection.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesCollection.doc(id).delete();
  }

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      {'name': 'Family', 'bnName': 'ফ্যামিলি', 'icon': 'family', 'isActive': true},
      {'name': 'Bachelor Male', 'bnName': 'ব্যাচেলর (ছাত্র/পুরুষ)', 'icon': 'male', 'isActive': true},
      {'name': 'Bachelor Female', 'bnName': 'ব্যাচেলর (ছাত্রী/মহিলা)', 'icon': 'female', 'isActive': true},
      {'name': 'Sublet', 'bnName': 'সাবলেট', 'icon': 'sublet', 'isActive': true},
      {'name': 'Hostel / Mess', 'bnName': 'হোস্টেল / মেস', 'icon': 'hostel', 'isActive': true},
      {'name': 'Commercial / Office', 'bnName': 'কমার্শিয়াল / অফিস', 'icon': 'office', 'isActive': true},
      {'name': 'Furniture Included', 'bnName': 'ফার্নিচার সহ বাসা', 'icon': 'furniture', 'isActive': true},
    ];
    for (final item in defaults) {
      await _categoriesCollection.add({
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ==========================================================================
  // 5. FAQ MANAGEMENT
  // ==========================================================================

  Stream<List<Map<String, dynamic>>> streamFaqs() {
    return _faqsCollection.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        _seedDefaultFaqs();
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> addFaq(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await _faqsCollection.add(data);
  }

  Future<void> updateFaq(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _faqsCollection.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteFaq(String id) async {
    await _faqsCollection.doc(id).delete();
  }

  Future<void> _seedDefaultFaqs() async {
    final defaultFaqs = [
      {
        'questionEn': 'How can I post a rental home?',
        'questionBn': 'কীভাবে বাসা ভাড়ার বিজ্ঞাপন দেব?',
        'answerEn': 'Create a House Owner account, click Post Rental, fill in property details and photos, and submit.',
        'answerBn': 'বাড়িওয়ালা অ্যাকাউন্ট তৈরি করুন, বাসাভাড়া পোস্ট এ ক্লিক করে প্রয়োজনীয় তথ্য ও ছবি দিন।',
        'category': 'General',
        'targetAudience': 'house_owner',
      },
      {
        'questionEn': 'How do I verify my account with NID?',
        'questionBn': 'এনআইডি দিয়ে প্রোফাইল কীভাবে ভেরিফাই করব?',
        'answerEn': 'Go to My Profile in Account screen, upload clear photos of your NID front and back, and click Save.',
        'answerBn': 'অ্যাকাউন্ট স্ক্রিন থেকে মাই প্রোফাইলে গিয়ে আপনার এনআইডির সামনের ও পেছনের স্পষ্ট ছবি আপলোড করে সেভ করুন।',
        'category': 'Verification',
        'targetAudience': 'all',
      },
      {
        'questionEn': 'Is posting rental demands free for tenants?',
        'questionBn': 'ভাড়াটিয়াদের জন্য চাহিদা পোস্ট কি সম্পূর্ণ ফ্রি?',
        'answerEn': 'Yes, tenants can post rental demands completely free of cost.',
        'answerBn': 'হ্যাঁ, ভাড়াটিয়ারা সম্পূর্ণ ফ্রিতে তাদের পছন্দের এলাকা ও বাজেটে চাহিদা পোস্ট করতে পারেন।',
        'category': 'Tenant',
        'targetAudience': 'tenant',
      },
    ];
    for (final faq in defaultFaqs) {
      await _faqsCollection.add({
        ...faq,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ==========================================================================
  // 6. GENERAL SETTINGS
  // ==========================================================================

  Stream<Map<String, dynamic>> streamSettings() {
    return _settingsDoc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        _seedDefaultSettings();
        return _defaultSettingsMap;
      }
      return snapshot.data() as Map<String, dynamic>;
    });
  }

  Stream<bool> streamAutoApprovalSetting() {
    return _settingsDoc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return true;
      final data = snapshot.data() as Map<String, dynamic>;
      return (data['autoApprovalEnabled'] as bool?) ?? true;
    });
  }

  Future<bool> getAutoApprovalStatus() async {
    try {
      final doc = await _settingsDoc.get();
      if (!doc.exists || doc.data() == null) return true;
      final data = doc.data() as Map<String, dynamic>;
      return (data['autoApprovalEnabled'] as bool?) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> toggleAutoApproval(bool enabled) async {
    await _settingsDoc.set({
      'autoApprovalEnabled': enabled,
      'autoApproveProperties': enabled,
      'autoApproveDemands': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _settingsDoc.set(data, SetOptions(merge: true));
  }

  Map<String, dynamic> get _defaultSettingsMap => {
    'appName': 'BashaBondhu Home Rental',
    'logoUrl': '',
    'bannerNotice': 'স্বাগতম বাসাবন্ধু হোম রেন্টাল ম্যানেজমেন্ট সিস্টেমে!',
    'bannerNoticeEn': 'Welcome to BashaBondhu Home Rental Management System!',
    'helpline': '+880 1700-000000',
    'supportEmail': 'support@bashabondhu.com',
    'officeAddress': 'House 12, Road 5, Dhanmondi, Dhaka - 1205',
    'facebookUrl': 'https://facebook.com/bashabondhu',
    'youtubeUrl': 'https://youtube.com/@bashabondhu',
    'whatsappNumber': '+8801700000000',
    'websiteUrl': 'https://bashabondhu.com',
    'termsAndConditions': 'BashaBondhu Terms & Conditions:\n1. All listings must be accurate and authentic.\n2. Users must respect privacy and security regulations.',
    'privacyPolicy': 'BashaBondhu Privacy Policy:\n1. We protect your personal information.\n2. NID verification data is encrypted and securely reviewed.',
    'autoApprovalEnabled': true,
    'autoApproveProperties': true,
    'autoApproveDemands': true,
  };

  Future<void> _seedDefaultSettings() async {
    await _settingsDoc.set(_defaultSettingsMap, SetOptions(merge: true));
  }
}
