import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_model.dart';
import '../models/free_tier_policy_model.dart';

class SubscriptionFirestoreService {
  static final SubscriptionFirestoreService _instance =
      SubscriptionFirestoreService._internal();
  factory SubscriptionFirestoreService() => _instance;
  SubscriptionFirestoreService._internal();

  static bool _hasCheckedSeeding = false;
  static bool _isSeeding = false;

  final CollectionReference _plansCollection =
      FirebaseFirestore.instance.collection('subscription_plans');
  final CollectionReference _transactionsCollection =
      FirebaseFirestore.instance.collection('subscription_transactions');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final DocumentReference _freeTierPolicyDoc =
      FirebaseFirestore.instance.collection('app_settings').doc('free_tier_policy');

  
  // FREE TIER POLICY CONFIGURATION (ADMIN)
  

  Stream<FreeTierPolicyModel> streamFreeTierPolicy() {
    return _freeTierPolicyDoc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return FreeTierPolicyModel.defaultPolicy();
      }
      try {
        final raw = snapshot.data();
        if (raw is Map) {
          return FreeTierPolicyModel.fromMap(Map<String, dynamic>.from(raw));
        }
        return FreeTierPolicyModel.defaultPolicy();
      } catch (e) {
        debugPrint('⚠️ Error parsing FreeTierPolicy: $e');
        return FreeTierPolicyModel.defaultPolicy();
      }
    }).handleError((e) {
      debugPrint('ℹ️ Handled FreeTierPolicy stream error: $e');
      return FreeTierPolicyModel.defaultPolicy();
    });
  }

  Future<FreeTierPolicyModel> getFreeTierPolicy() async {
    try {
      final snapshot = await _freeTierPolicyDoc.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return FreeTierPolicyModel.defaultPolicy();
      }
      return FreeTierPolicyModel.fromMap(snapshot.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting FreeTierPolicy: $e');
      return FreeTierPolicyModel.defaultPolicy();
    }
  }

  Future<void> saveFreeTierPolicy(FreeTierPolicyModel policy) async {
    try {
      final map = policy.toMap();
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _freeTierPolicyDoc.set(map, SetOptions(merge: true));
      debugPrint('✅ Free tier policy saved to Firestore successfully!');
    } catch (e) {
      debugPrint('❌ Error saving free tier policy: $e');
      rethrow;
    }
  }

  /// Save only Tenant Free Tier Policy fields to Firestore
  Future<void> saveTenantFreeTierPolicy(Map<String, dynamic> tenantData) async {
    try {
      final map = Map<String, dynamic>.from(tenantData);
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _freeTierPolicyDoc.set(map, SetOptions(merge: true));
      debugPrint('✅ Tenant free tier policy saved to Firestore successfully!');
    } catch (e) {
      debugPrint('❌ Error saving tenant free tier policy: $e');
      rethrow;
    }
  }

  /// Save only House Owner Free Tier Policy fields to Firestore
  Future<void> saveOwnerFreeTierPolicy(Map<String, dynamic> ownerData) async {
    try {
      final map = Map<String, dynamic>.from(ownerData);
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _freeTierPolicyDoc.set(map, SetOptions(merge: true));
      debugPrint('✅ House Owner free tier policy saved to Firestore successfully!');
    } catch (e) {
      debugPrint('❌ Error saving house owner free tier policy: $e');
      rethrow;
    }
  }

  
  // SUBSCRIPTION PLANS CRUD & SEEDING
  

  /// Seed initial default plans into Firestore if not yet seeded
  Future<void> seedDefaultPlansIfEmpty({bool forceCheck = false}) async {
    // 1. In-memory check: prevent redundant execution during app lifecycle
    if (!forceCheck) {
      if (_hasCheckedSeeding || _isSeeding) return;

      // 2. Local SharedPreferences check: avoid Firestore/network queries on startup
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('has_seeded_subscription_plans_v1') == true) {
          _hasCheckedSeeding = true;
          return;
        }
      } catch (_) {}
    } else {
      if (_isSeeding) return;
    }

    // 3. Auth guard: do not make unauthenticated Firestore queries that trigger permission-denied
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    _isSeeding = true;
    try {
      // 4. Safe query with cache source and strict timeout
      final existingPlans = await _plansCollection
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (existingPlans.docs.isNotEmpty) {
        _hasCheckedSeeding = true;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_seeded_subscription_plans_v1', true);
        } catch (_) {}
        return;
      }

      debugPrint('🌱 Seeding initial subscription plans into Firestore...');
      final defaultPlans = _getDefaultPlans();
      final batch = FirebaseFirestore.instance.batch();
      for (final plan in defaultPlans) {
        batch.set(_plansCollection.doc(plan.id), plan.toMap());
      }
      await batch.commit();
      _hasCheckedSeeding = true;
      debugPrint('✅ 6 Default subscription plans seeded successfully into Firestore!');

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seeded_subscription_plans_v1', true);
      } catch (_) {}

      try {
        final metaDoc = FirebaseFirestore.instance.collection('app_settings').doc('subscription_meta');
        await metaDoc.set({'isSeeded': true, 'seededAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      } catch (_) {}
    } on FirebaseException catch (fe) {
      debugPrint('ℹ️ Subscription plans check skipped (${fe.code}): ${fe.message}');
      _hasCheckedSeeding = true;
    } catch (e) {
      debugPrint('ℹ️ Subscription plans check skipped: $e');
      _hasCheckedSeeding = true;
    } finally {
      _isSeeding = false;
    }
  }

  /// Manually restore or seed default 6 plans into Firestore (for Admin)
  Future<void> restoreDefaultPlans() async {
    try {
      final defaultPlans = _getDefaultPlans();
      final batch = FirebaseFirestore.instance.batch();
      for (final plan in defaultPlans) {
        batch.set(_plansCollection.doc(plan.id), plan.toMap());
      }
      await batch.commit();
      _hasCheckedSeeding = true;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seeded_subscription_plans_v1', true);
      } catch (_) {}

      try {
        final metaDoc = FirebaseFirestore.instance.collection('app_settings').doc('subscription_meta');
        await metaDoc.set({'isSeeded': true, 'restoredAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      } catch (_) {}

      debugPrint('✅ 6 Default subscription plans restored successfully into Firestore!');
    } catch (e) {
      debugPrint('❌ Error restoring default subscription plans: $e');
      rethrow;
    }
  }

  /// Stream active plans for a specific target role (derived from streamAllPlans)
  Stream<List<SubscriptionPlanModel>> streamPlans(SubscriptionTargetRole role) {
    return streamAllPlans().map((plans) {
      return plans.where((p) => p.targetRole == role).toList();
    });
  }

  /// Stream all plans for Admin panel (direct query stream)
  Stream<List<SubscriptionPlanModel>> streamAllPlans() {
    return _plansCollection.snapshots().map((snapshot) {
      final List<SubscriptionPlanModel> plans = [];
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          if (raw is Map) {
            plans.add(SubscriptionPlanModel.fromMap(
                Map<String, dynamic>.from(raw), doc.id));
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing plan ${doc.id}: $e');
        }
      }
      plans.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return plans;
    }).handleError((e) {
      debugPrint('ℹ️ Handled plans stream error: $e');
      return <SubscriptionPlanModel>[];
    });
  }

  /// Create new custom plan by Admin
  Future<void> createPlan(SubscriptionPlanModel plan) async {
    try {
      final docRef = plan.id.isNotEmpty ? _plansCollection.doc(plan.id) : _plansCollection.doc();
      final finalPlan = plan.id.isNotEmpty ? plan : plan.copyWith(id: docRef.id);
      await docRef.set(finalPlan.toMap());
      debugPrint('✅ Subscription plan created: ${finalPlan.id}');
    } catch (e) {
      debugPrint('❌ Error creating subscription plan: $e');
      rethrow;
    }
  }

  /// Update plan (Price, Offers, Badges, Perks, Quotas by Admin)
  Future<void> updatePlan(SubscriptionPlanModel plan) async {
    try {
      await _plansCollection.doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
      debugPrint('✅ Subscription plan updated: ${plan.id}');
    } catch (e) {
      debugPrint('❌ Error updating subscription plan: $e');
      rethrow;
    }
  }

  /// Delete a plan by Admin
  Future<void> deletePlan(String planId) async {
    try {
      await _plansCollection.doc(planId).delete();
      debugPrint('🗑️ Subscription plan deleted: $planId');
    } catch (e) {
      debugPrint('❌ Error deleting subscription plan: $e');
      rethrow;
    }
  }

  
  // MULTI-PLAN PURCHASE & ACTIVATION
  

  /// Record a new purchase / payment and activate user subscription (appends to activeSubscriptionPlans)
  Future<void> purchaseSubscription({
    required String userId,
    required String userEmail,
    required String userMobile,
    required SubscriptionPlanModel plan,
    required String transactionId,
    required String senderPhone,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: plan.durationDays));

      final docRef = _transactionsCollection.doc();
      final transaction = SubscriptionTransactionModel(
        id: docRef.id,
        userId: userId,
        userEmail: userEmail,
        userMobile: userMobile,
        planId: plan.id,
        planTitle: plan.titleBn,
        amountPaid: plan.effectivePrice,
        paymentMethod: 'bKash',
        transactionId: transactionId,
        senderPhone: senderPhone,
        purchasedAt: now,
        expiresAt: expiresAt,
        status: 'active',
      );

      await docRef.set(transaction.toMap());

      // Create UserSubscriptionPlan snapshot
      final userPlan = UserSubscriptionPlan(
        id: docRef.id,
        planId: plan.id,
        titleBn: plan.titleBn,
        titleEn: plan.titleEn,
        purchasedAt: now,
        expiresAt: expiresAt,
        amountPaid: plan.effectivePrice,
        durationDays: plan.durationDays,
        maxPostsLimit: plan.maxPostsLimit,
        postsUsed: 0,
        unlockNumbersLimit: plan.unlockNumbersLimit,
        unlocksUsed: 0,
        subAreaUnlockLimit: plan.subAreaUnlockLimit,
        subAreaUnlocksUsed: 0,
        fullPhotoGalleryLimit: plan.fullPhotoGalleryLimit,
        photoGalleryUsed: 0,
        nearbySearchLimit: plan.nearbySearchLimit,
        nearbySearchUsed: 0,
        mapDirectionsLimit: plan.mapDirectionsLimit,
        mapDirectionsUsed: 0,
        aiAssistantLimit: plan.aiAssistantLimit,
        aiAssistantUsed: 0,
      );

      // Append to user's activeSubscriptionPlans array and update legacy fields
      await _usersCollection.doc(userId).set({
        'subscriptionPlanId': plan.id,
        'subscriptionExpiryDate': expiresAt.toIso8601String(),
        'activeSubscriptionPlans': FieldValue.arrayUnion([userPlan.toMap()]),
        // Legacy fields for backward compatibility
        'subscriptionMaxPosts': plan.maxPostsLimit,
        'subscriptionMaxUnlocks': plan.unlockNumbersLimit,
        'subscriptionCanAccessPhotos': plan.canAccessAdditionalPhotos,
        'subscriptionMaxNearbySearches': plan.nearbySearchLimit,
        'subscriptionMaxMapDirections': plan.mapDirectionsLimit,
        'subscriptionMaxAiQueries': plan.aiAssistantLimit,
      }, SetOptions(merge: true));

      debugPrint('🎉 Subscription activated (Plan added) for $userId until $expiresAt');
    } catch (e) {
      debugPrint('❌ Error recording subscription purchase: $e');
      rethrow;
    }
  }

  
  // MULTI-PLAN QUOTA CONSUMPTION
  

  String _getLimitKeyForFacility(String facility) {
    switch (facility) {
      case 'posts':
        return 'maxPostsLimit';
      case 'unlocks':
        return 'unlockNumbersLimit';
      case 'subAreaUnlocks':
        return 'subAreaUnlockLimit';
      case 'photoGallery':
        return 'fullPhotoGalleryLimit';
      case 'nearbySearch':
        return 'nearbySearchLimit';
      case 'mapDirections':
        return 'mapDirectionsLimit';
      case 'aiAssistant':
        return 'aiAssistantLimit';
      default:
        return '${facility}Limit';
    }
  }

  /// Increment a facility's used count in the first active plan with remaining quota
  Future<void> _incrementActivePlanQuota(String userId, String facility) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists || doc.data() == null) return;
      final data = doc.data() as Map<String, dynamic>;
      final rawPlans = data['activeSubscriptionPlans'] as List?;
      if (rawPlans == null || rawPlans.isEmpty) return;

      final List<Map<String, dynamic>> updatedList = [];
      bool deducted = false;

      for (final raw in rawPlans) {
        if (raw is Map) {
          final planMap = Map<String, dynamic>.from(raw);
          final expiryVal = planMap['expiresAt'];
          DateTime? exp;
          if (expiryVal is Timestamp) exp = expiryVal.toDate();
          if (expiryVal is String) exp = DateTime.tryParse(expiryVal);

          final isActive = exp != null && exp.isAfter(DateTime.now());
          if (isActive && !deducted) {
            final limitKey = _getLimitKeyForFacility(facility);
            final limitVal = (planMap[limitKey] as num?)?.toInt() ?? -1;
            final usedKey = '${facility}Used';
            final currentUsed = (planMap[usedKey] as num?)?.toInt() ?? 0;
            final hasQuota = limitVal == -1 || (limitVal > 0 && currentUsed < limitVal);

            if (hasQuota) {
              planMap[usedKey] = currentUsed + 1;
              deducted = true;
            }
          }
          updatedList.add(planMap);
        }
      }

      if (deducted) {
        await _usersCollection.doc(userId).update({
          'activeSubscriptionPlans': updatedList,
        });
      }
    } catch (e) {
      debugPrint('Error updating active plan quota ($facility): $e');
    }
  }

  /// Unlock a property info for Tenant (adds propertyId to unlockedPropertyIds & updates quota)
  Future<void> unlockPropertyForUser(String userId, String propertyId, {bool isSubscribed = false}) async {
    try {
      final Map<String, dynamic> updates = {
        'unlockedPropertyIds': FieldValue.arrayUnion([propertyId]),
      };
      if (isSubscribed) {
        updates['subscriptionUnlocksCount'] = FieldValue.increment(1);
        await _incrementActivePlanQuota(userId, 'unlocks');
      }
      await _usersCollection.doc(userId).update(updates);
      debugPrint('🔓 Property $propertyId unlocked for user $userId (subscribed: $isSubscribed)');
    } catch (e) {
      debugPrint('❌ Error unlocking property: $e');
      rethrow;
    }
  }

  /// Unlock a demand contact info for House Owner (adds demandId to unlockedDemandIds & updates quota)
  Future<void> unlockDemandForUser(String userId, String demandId, {bool isSubscribed = false}) async {
    try {
      final Map<String, dynamic> updates = {
        'unlockedDemandIds': FieldValue.arrayUnion([demandId]),
      };
      if (isSubscribed) {
        updates['subscriptionUnlocksCount'] = FieldValue.increment(1);
        await _incrementActivePlanQuota(userId, 'unlocks');
      }
      await _usersCollection.doc(userId).update(updates);
      debugPrint('🔓 Demand $demandId unlocked for user $userId (subscribed: $isSubscribed)');
    } catch (e) {
      debugPrint('❌ Error unlocking demand: $e');
      rethrow;
    }
  }

  /// Unlock Sub-Area of a property for Tenant
  Future<void> unlockPropertySubAreaForUser(String userId, String propertyId, {bool isSubscribed = false}) async {
    try {
      final Map<String, dynamic> updates = {
        'unlockedPropertySubAreaIds': FieldValue.arrayUnion([propertyId]),
      };
      if (isSubscribed) {
        updates['subscriptionSubAreaUnlocksCount'] = FieldValue.increment(1);
        await _incrementActivePlanQuota(userId, 'subAreaUnlocks');
      }
      await _usersCollection.doc(userId).update(updates);
      debugPrint('📍 Property sub-area $propertyId unlocked for user $userId (subscribed: $isSubscribed)');
    } catch (e) {
      debugPrint('❌ Error unlocking property sub-area: $e');
      rethrow;
    }
  }

  /// Unlock Full Photo Gallery of a property for Tenant
  Future<void> unlockPhotoGalleryForUser(String userId, String propertyId, {bool isSubscribed = false}) async {
    try {
      final Map<String, dynamic> updates = {
        'unlockedPhotoPropertyIds': FieldValue.arrayUnion([propertyId]),
      };
      if (isSubscribed) {
        await _incrementActivePlanQuota(userId, 'photoGallery');
      }
      await _usersCollection.doc(userId).update(updates);
      debugPrint('🖼️ Photo gallery $propertyId unlocked for user $userId (subscribed: $isSubscribed)');
    } catch (e) {
      debugPrint('❌ Error unlocking photo gallery: $e');
      rethrow;
    }
  }

  /// Unlock Sub-Area of a demand for House Owner
  Future<void> unlockDemandSubAreaForUser(String userId, String demandId, {bool isSubscribed = false}) async {
    try {
      final Map<String, dynamic> updates = {
        'unlockedDemandSubAreaIds': FieldValue.arrayUnion([demandId]),
      };
      if (isSubscribed) {
        updates['subscriptionSubAreaUnlocksCount'] = FieldValue.increment(1);
        await _incrementActivePlanQuota(userId, 'subAreaUnlocks');
      }
      await _usersCollection.doc(userId).update(updates);
      debugPrint('📍 Demand sub-area $demandId unlocked for user $userId (subscribed: $isSubscribed)');
    } catch (e) {
      debugPrint('❌ Error unlocking demand sub-area: $e');
      rethrow;
    }
  }

  /// Unlock Sub-Area generic wrapper
  Future<void> unlockSubAreaForUser(String userId, String targetId, {bool isSubscribed = false}) async {
    try {
      if (isSubscribed) {
        await _incrementActivePlanQuota(userId, 'subAreaUnlocks');
      }
      debugPrint('📍 Sub-area unlocked for $targetId (user: $userId)');
    } catch (e) {
      debugPrint('Error unlocking sub-area: $e');
    }
  }

  /// Increment post count when a house owner posts property or tenant posts demand
  Future<void> incrementPostCount(String userId, {bool isSubscribed = false}) async {
    try {
      await _usersCollection.doc(userId).update({
        'subscriptionPostsCount': FieldValue.increment(1),
      });
      if (isSubscribed) {
        await _incrementActivePlanQuota(userId, 'posts');
      }
      debugPrint('📝 Post count incremented for user $userId');
    } catch (e) {
      debugPrint('Error incrementing post count: $e');
    }
  }

  /// Increment radius / nearby search count (tracked for free or subscriber)
  Future<void> incrementRadiusSearchCount(String userId, {bool isSubscribed = false}) async {
    try {
      if (isSubscribed) {
        await _usersCollection.doc(userId).update({
          'subscriptionNearbySearchCount': FieldValue.increment(1),
        });
        await _incrementActivePlanQuota(userId, 'nearbySearch');
      } else {
        await _usersCollection.doc(userId).update({
          'radiusSearchCount': FieldValue.increment(1),
        });
      }
      debugPrint('📍 Radius search incremented for $userId (subscribed: $isSubscribed)');
    } catch (e) {
      debugPrint('Error incrementing radius search count: $e');
    }
  }

  /// Increment Google Maps Directions usage count
  Future<void> incrementMapDirectionCount(String userId, {bool isSubscribed = false}) async {
    try {
      await _usersCollection.doc(userId).update({
        'subscriptionMapDirectionsCount': FieldValue.increment(1),
      });
      if (isSubscribed) {
        await _incrementActivePlanQuota(userId, 'mapDirections');
      }
      debugPrint('🧭 Map directions incremented for user $userId');
    } catch (e) {
      debugPrint('Error incrementing map directions count: $e');
    }
  }

  /// Increment AI Assistant query count
  Future<void> incrementAiQueryCount(String userId, {bool isSubscribed = false}) async {
    try {
      await _usersCollection.doc(userId).update({
        'aiAssistantQueryCount': FieldValue.increment(1),
      });
      if (isSubscribed) {
        await _incrementActivePlanQuota(userId, 'aiAssistant');
      }
      debugPrint('🤖 AI query count incremented for user $userId');
    } catch (e) {
      debugPrint('Error incrementing AI query count: $e');
    }
  }

  
  // TRANSACTION HISTORY
  

  /// Stream transaction history for a specific user
  Stream<List<SubscriptionTransactionModel>> streamUserTransactions(String userId) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final List<SubscriptionTransactionModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          if (raw is Map) {
            list.add(SubscriptionTransactionModel.fromMap(
                Map<String, dynamic>.from(raw), doc.id));
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing user transaction ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      return list;
    });
  }

  /// Stream all transactions for Admin panel (direct query stream)
  Stream<List<SubscriptionTransactionModel>> streamAllTransactions() {
    return _transactionsCollection.snapshots().map((snapshot) {
      final List<SubscriptionTransactionModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          if (raw is Map) {
            list.add(SubscriptionTransactionModel.fromMap(
                Map<String, dynamic>.from(raw), doc.id));
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing transaction ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      return list;
    }).handleError((e) {
      debugPrint('ℹ️ Handled transactions stream error: $e');
      return <SubscriptionTransactionModel>[];
    });
  }

  
  // INITIAL SEED PLANS
  

  List<SubscriptionPlanModel> _getDefaultPlans() {
    return [
      // 1. Tenant Package: 100 Taka (7 Days)
      const SubscriptionPlanModel(
        id: 'tenant_7_days',
        titleEn: '7-Day Support',
        titleBn: '৭ দিনের সাপোর্ট প্যাকেজ',
        descriptionEn: 'Full contact unlock & search for 7 days',
        descriptionBn: '৭ দিনের জন্য আনলিমিটেড বাড়িওয়ালার নম্বর আনলক ও সাপোর্ট',
        regularPrice: 100.0,
        durationDays: 7,
        durationEn: '7 Days',
        durationBn: '৭ দিন',
        targetRole: SubscriptionTargetRole.tenant,
        perksEn: [
          'Unlock unlimited numbers including this post',
          'Post up to 5 customized rental demands',
          'Unlimited access to all additional owner photos for 7 days',
          'Full access to all property sub-area locations',
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '৫টি ভিন্ন চাহিদা জানাতে পারবেন',
          'বাড়িওয়ালার অতিরিক্ত সকল ছবি ৭ দিন আনলিমিটেড দেখতে পারবেন',
          'সকল বাসার সাব-এরিয়া লোকেশন উন্মুক্ত',
        ],
        isPopular: false,
        displayOrder: 1,
        maxPostsLimit: 5,
        unlockNumbersLimit: -1,
        subAreaUnlockLimit: -1,
        fullPhotoGalleryLimit: -1,
        canAccessAdditionalPhotos: true,
        nearbySearchLimit: 10,
        mapDirectionsLimit: 10,
        aiAssistantLimit: -1,
      ),

      // 2. Tenant Package: 200 Taka (15 Days)
      const SubscriptionPlanModel(
        id: 'tenant_15_days',
        titleEn: '15-Day Premium',
        titleBn: '১৫ দিনের প্রিমিয়াম প্যাকেজ',
        descriptionEn: 'Most popular package for active house hunting',
        descriptionBn: 'বাসা খোঁজার সেরা ১৫ দিনের আকর্ষণীয় প্রিমিয়াম প্যাকেজ',
        regularPrice: 200.0,
        durationDays: 15,
        durationEn: '15 Days',
        durationBn: '১৫ দিন',
        targetRole: SubscriptionTargetRole.tenant,
        perksEn: [
          'Unlock unlimited numbers including this post',
          'Post up to 10 customized rental demands',
          'Unlimited access to all additional owner photos for 15 days',
          'Full access to all property sub-area locations',
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '১০টি ভিন্ন চাহিদা জানাতে পারবেন',
          'বাড়িওয়ালার অতিরিক্ত সকল ছবি ১৫ দিন আনলিমিটেড দেখতে পারবেন',
          'সকল বাসার সাব-এরিয়া লোকেশন উন্মুক্ত',
        ],
        isPopular: true,
        displayOrder: 2,
        maxPostsLimit: 10,
        unlockNumbersLimit: -1,
        subAreaUnlockLimit: -1,
        fullPhotoGalleryLimit: -1,
        canAccessAdditionalPhotos: true,
        nearbySearchLimit: 20,
        mapDirectionsLimit: 20,
        aiAssistantLimit: -1,
      ),

      // 3. Tenant Package: 350 Taka (30 Days)
      const SubscriptionPlanModel(
        id: 'tenant_30_days',
        titleEn: '30-Day VIP Support',
        titleBn: '৩০ দিনের ভিআইপি প্যাকেজ',
        descriptionEn: 'Full access for 30 days with all premium facilities',
        descriptionBn: 'সম্পূর্ণ ৩০ দিনের আনলিমিটেড সব প্রিমিয়াম সুবিধা',
        regularPrice: 350.0,
        durationDays: 30,
        durationEn: '30 Days',
        durationBn: '৩০ দিন',
        targetRole: SubscriptionTargetRole.tenant,
        perksEn: [
          'Unlock unlimited numbers including this post',
          'Post up to 20 customized rental demands',
          'Unlimited access to all additional owner photos for 30 days',
          'Full access to all property sub-area locations',
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '২০টি ভিন্ন চাহিদা জানাতে পারবেন',
          'বাড়িওয়ালার অতিরিক্ত সকল ছবি ৩০ দিন আনলিমিটেড দেখতে পারবেন',
          'সকল বাসার সাব-এরিয়া লোকেশন উন্মুক্ত',
        ],
        isPopular: false,
        displayOrder: 3,
        maxPostsLimit: 20,
        unlockNumbersLimit: -1,
        subAreaUnlockLimit: -1,
        fullPhotoGalleryLimit: -1,
        canAccessAdditionalPhotos: true,
        nearbySearchLimit: -1,
        mapDirectionsLimit: -1,
        aiAssistantLimit: -1,
      ),

      // 4. House Owner Package: 300 Taka (15 Days)
      const SubscriptionPlanModel(
        id: 'owner_15_days',
        titleEn: '15-Day Starter',
        titleBn: '১৫ দিনের স্টার্টার প্যাকেজ',
        descriptionEn: 'Publish listings and unlock tenant contacts for 15 days',
        descriptionBn: '১৫ দিনের জন্য বাসাভাড়া বিজ্ঞাপন ও ভাড়াটিয়াদের নম্বর আনলক',
        regularPrice: 300.0,
        durationDays: 15,
        durationEn: '15 Days',
        durationBn: '১৫ দিন',
        targetRole: SubscriptionTargetRole.houseOwner,
        perksEn: [
          'Unlock unlimited tenant contact numbers',
          'Post up to 10 rental listings',
          'Full access to tenant demand sub-areas',
        ],
        perksBn: [
          'ভাড়াটিয়াদের আনলিমিটেড ফোন নম্বর আনলক',
          '১০টি পোস্ট করতে পারবেন',
          'ভাড়াটিয়াদের চাহিদার সকল সাব-এরিয়া উন্মুক্ত',
        ],
        isPopular: false,
        displayOrder: 1,
        maxPostsLimit: 10,
        unlockNumbersLimit: -1,
        subAreaUnlockLimit: -1,
        fullPhotoGalleryLimit: 0,
        canAccessAdditionalPhotos: false,
        nearbySearchLimit: 0,
        mapDirectionsLimit: 0,
        aiAssistantLimit: 20,
      ),

      // 5. House Owner Package: 500 Taka (30 Days)
      const SubscriptionPlanModel(
        id: 'owner_30_days',
        titleEn: '30-Day Standard',
        titleBn: '৩০ দিনের স্ট্যান্ডার্ড প্যাকেজ',
        descriptionEn: '30 Days unlimited posts and tenant contacts',
        descriptionBn: '৩০ দিনের জন্য সেরা বিজ্ঞাপন ও ভাড়াটিয়া কানেক্ট প্যাকেজ',
        regularPrice: 500.0,
        durationDays: 30,
        durationEn: '30 Days',
        durationBn: '৩০ দিন',
        targetRole: SubscriptionTargetRole.houseOwner,
        perksEn: [
          'Unlock unlimited tenant contact numbers',
          'Post up to 20 rental listings',
          'Full access to tenant demand sub-areas',
        ],
        perksBn: [
          'ভাড়াটিয়াদের আনলিমিটেড ফোন নম্বর আনলক',
          '২০টি পোস্ট করতে পারবেন',
          'ভাড়াটিয়াদের চাহিদার সকল সাব-এরিয়া উন্মুক্ত',
        ],
        isPopular: true,
        displayOrder: 2,
        maxPostsLimit: 20,
        unlockNumbersLimit: -1,
        subAreaUnlockLimit: -1,
        fullPhotoGalleryLimit: 0,
        canAccessAdditionalPhotos: false,
        nearbySearchLimit: 0,
        mapDirectionsLimit: 0,
        aiAssistantLimit: 50,
      ),

      // 6. House Owner Package: 1000 Taka (30 Days Unlimited)
      const SubscriptionPlanModel(
        id: 'owner_30_days_vip',
        titleEn: '30-Day VIP Unlimited',
        titleBn: '৩০ দিনের আনলিমিটেড প্যাকেজ',
        descriptionEn: 'Maximum exposure and unlimited access across the system',
        descriptionBn: 'সর্বোচ্চ প্রচার ও সিস্টেমের সকল আনলিমিটেড সুযোগ-সুবিধা',
        regularPrice: 1000.0,
        durationDays: 30,
        durationEn: '30 Days',
        durationBn: '৩০ দিন',
        targetRole: SubscriptionTargetRole.houseOwner,
        perksEn: [
          'Unlock unlimited tenant contact numbers',
          'Unlimited rental listings',
          'Full access to tenant demand sub-areas',
          'Unlimited AI Assistant property queries',
        ],
        perksBn: [
          'ভাড়াটিয়াদের আনলিমিটেড ফোন নম্বর আনলক',
          'আনলিমিটেড পোস্ট করতে পারবেন',
          'ভাড়াটিয়াদের চাহিদার সকল সাব-এরিয়া উন্মুক্ত',
          'আনলিমিটেড এআই সহকারী (AI Assistant) সার্চ',
        ],
        isPopular: false,
        isUnlimited: true,
        displayOrder: 3,
        maxPostsLimit: -1,
        unlockNumbersLimit: -1,
        subAreaUnlockLimit: -1,
        fullPhotoGalleryLimit: 0,
        canAccessAdditionalPhotos: false,
        nearbySearchLimit: 0,
        mapDirectionsLimit: 0,
        aiAssistantLimit: -1,
      ),
    ];
  }
}
