import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';

class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _propertiesCollection => _firestore.collection('properties');
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

  Future<void> updateUserBlockStatus(String uid, bool isBlocked) async {
    await _usersCollection.doc(uid).set({
      'isBlocked': isBlocked,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserNidStatus(String uid, String status, {String? reason}) async {
    final Map<String, dynamic> updateData = {
      'nidVerificationStatus': status, // 'verified', 'rejected', 'pending'
      'nidVerificationDate': FieldValue.serverTimestamp(),
    };
    if (reason != null && reason.isNotEmpty) {
      updateData['nidRejectionReason'] = reason;
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
    final Map<String, dynamic> updateData = {
      'approvalStatus': status, // 'approved', 'pending', 'rejected'
      'isApproved': status == 'approved',
      'approvalDate': FieldValue.serverTimestamp(),
    };
    if (reason != null && reason.isNotEmpty) {
      updateData['rejectionReason'] = reason;
    }
    await _propertiesCollection.doc(propertyId).set(updateData, SetOptions(merge: true));
  }

  Future<void> deleteProperty(String propertyId) async {
    await _propertiesCollection.doc(propertyId).delete();
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
  };

  Future<void> _seedDefaultSettings() async {
    await _settingsDoc.set(_defaultSettingsMap, SetOptions(merge: true));
  }
}
