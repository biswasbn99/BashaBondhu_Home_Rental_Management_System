import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_model.dart';

class SubscriptionFirestoreService {
  static final SubscriptionFirestoreService _instance =
      SubscriptionFirestoreService._internal();
  factory SubscriptionFirestoreService() => _instance;
  SubscriptionFirestoreService._internal();

  final CollectionReference _plansCollection =
      FirebaseFirestore.instance.collection('subscription_plans');
  final CollectionReference _transactionsCollection =
      FirebaseFirestore.instance.collection('subscription_transactions');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Seed initial default plans if collection is empty
  Future<void> seedDefaultPlansIfEmpty() async {
    try {
      final snapshot = await _plansCollection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('🌱 Seeding initial subscription plans...');
        final defaultPlans = _getDefaultPlans();
        for (final plan in defaultPlans) {
          await _plansCollection.doc(plan.id).set(plan.toMap());
        }
        debugPrint('✅ 6 Default subscription plans seeded successfully!');
      }
    } catch (e) {
      debugPrint('⚠️ Error seeding default subscription plans: $e');
    }
  }

  /// Stream active plans for a specific target role
  Stream<List<SubscriptionPlanModel>> streamPlans(SubscriptionTargetRole role) {
    final roleStr = role == SubscriptionTargetRole.tenant ? 'tenant' : 'houseOwner';
    return _plansCollection
        .where('targetRole', isEqualTo: roleStr)
        .snapshots()
        .map((snapshot) {
      final plans = snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (plans.isEmpty) {
        return _getDefaultPlans().where((p) => p.targetRole == role).toList();
      }
      plans.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return plans;
    });
  }

  /// Stream all plans for Admin panel
  Stream<List<SubscriptionPlanModel>> streamAllPlans() {
    return _plansCollection.snapshots().map((snapshot) {
      final plans = snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (plans.isEmpty) {
        return _getDefaultPlans();
      }
      plans.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return plans;
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

  /// Update plan (Price, Offers, Badges, Perks, etc. by Admin)
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

  /// Record a new purchase / payment and activate user subscription
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

      // Update User Document in Firestore with new subscription
      await _usersCollection.doc(userId).set({
        'subscriptionPlanId': plan.id,
        'subscriptionExpiryDate': expiresAt.toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('🎉 Subscription activated for $userId until $expiresAt');
    } catch (e) {
      debugPrint('❌ Error recording subscription purchase: $e');
      rethrow;
    }
  }

  /// Unlock a property info for Tenant (adds propertyId to unlockedPropertyIds)
  Future<void> unlockPropertyForUser(String userId, String propertyId) async {
    try {
      await _usersCollection.doc(userId).update({
        'unlockedPropertyIds': FieldValue.arrayUnion([propertyId]),
      });
      debugPrint('🔓 Property $propertyId unlocked for user $userId');
    } catch (e) {
      debugPrint('❌ Error unlocking property: $e');
      rethrow;
    }
  }

  /// Unlock a demand contact info for House Owner (adds demandId to unlockedDemandIds)
  Future<void> unlockDemandForUser(String userId, String demandId) async {
    try {
      await _usersCollection.doc(userId).update({
        'unlockedDemandIds': FieldValue.arrayUnion([demandId]),
      });
      debugPrint('🔓 Demand $demandId unlocked for user $userId');
    } catch (e) {
      debugPrint('❌ Error unlocking demand: $e');
      rethrow;
    }
  }

  /// Increment radius search count for Free Tenant
  Future<void> incrementRadiusSearchCount(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'radiusSearchCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing radius search count: $e');
    }
  }

  /// Stream transaction history for a specific user
  Stream<List<SubscriptionTransactionModel>> streamUserTransactions(String userId) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SubscriptionTransactionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      return list;
    });
  }

  /// Stream all transactions for Admin panel
  Stream<List<SubscriptionTransactionModel>> streamAllTransactions() {
    return _transactionsCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SubscriptionTransactionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      return list;
    });
  }

  /// Seed initial packages as specified by user requirements
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
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '৫টি ভিন্ন চাহিদা জানাতে পারবেন',
          'বাড়িওয়ালার অতিরিক্ত সকল ছবি ৭ দিন আনলিমিটেড দেখতে পারবেন',
        ],
        isPopular: false,
        displayOrder: 1,
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
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '১০টি ভিন্ন চাহিদা জানাতে পারবেন',
          'বাড়িওয়ালার অতিরিক্ত সকল ছবি ১৫ দিন আনলিমিটেড দেখতে পারবেন',
        ],
        isPopular: true,
        displayOrder: 2,
      ),

      // 3. Tenant Package: 350 Taka (30 Days)
      const SubscriptionPlanModel(
        id: 'tenant_30_days',
        titleEn: '30-Day VIP Support',
        titleBn: '৩০ দিনের ভিআইপি প্যাকেজ',
        descriptionEn: 'Full access for 30 days with ad-free experience',
        descriptionBn: 'সম্পূর্ণ ৩০ দিনের আনলিমিটেড সব প্রিমিয়াম সুবিধা',
        regularPrice: 350.0,
        durationDays: 30,
        durationEn: '30 Days',
        durationBn: '৩০ দিন',
        targetRole: SubscriptionTargetRole.tenant,
        perksEn: [
          'Unlock unlimited numbers including this post',
          'Post up to 20 customized rental demands',
          'Ad-free experience',
          'Unlimited access to all additional owner photos for 30 days',
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '২০টি ভিন্ন চাহিদা জানাতে পারবেন',
          'বিজ্ঞাপন দেখতে হবে না',
          'বাড়িওয়ালার অতিরিক্ত সকল ছবি ৩০ দিন আনলিমিটেড দেখতে পারবেন',
        ],
        isPopular: false,
        displayOrder: 3,
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
          'Ad-free experience',
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '১০টি পোস্ট করতে পারবেন',
          'বিজ্ঞাপন দেখতে হবে না',
        ],
        isPopular: false,
        displayOrder: 1,
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
          'Ad-free experience',
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          '২০টি পোস্ট করতে পারবেন',
          'বিজ্ঞাপন দেখতে হবে না',
        ],
        isPopular: true,
        displayOrder: 2,
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
          'Ad-free experience',
        ],
        perksBn: [
          'এই পোস্টসহ আনলিমিটেড নাম্বার আনলক করতে পারবেন',
          'আনলিমিটেড পোস্ট করতে পারবেন',
          'বিজ্ঞাপন দেখতে হবে না',
        ],
        isPopular: false,
        isUnlimited: true,
        displayOrder: 3,
      ),
    ];
  }
}
