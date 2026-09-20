import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import '../models/subscription_model.dart';
import '../models/free_tier_policy_model.dart';
import '../services/subscription_firestore_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionFirestoreService _service = SubscriptionFirestoreService();
  bool _isLoading = false;
  String? _errorMessage;
  FreeTierPolicyModel? _currentPolicy = FreeTierPolicyModel.defaultPolicy();
  StreamSubscription<FreeTierPolicyModel>? _policySubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FreeTierPolicyModel? get currentPolicy => _currentPolicy;
  bool _isDisposed = false;

  SubscriptionProvider() {
    _initPolicyListener();
  }

  void _initPolicyListener() {
    _policySubscription = _service.streamFreeTierPolicy().listen(
      (policy) {
        if (_isDisposed) return;
        if (_currentPolicy != policy) {
          _currentPolicy = policy;
          // Avoid calling notifyListeners() synchronously during widget tree build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              notifyListeners();
            }
          });
        }
      },
      onError: (e) {
        debugPrint('⚠️ Error streaming free tier policy: $e');
      },
      cancelOnError: false,
    );
  }

  /// Trigger seeding manually if needed
  Future<void> seedDefaultPlansIfEmpty() async {
    await _service.seedDefaultPlansIfEmpty();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _policySubscription?.cancel();
    super.dispose();
  }

  /// Stream Free Tier Policy for Admin & Users
  Stream<FreeTierPolicyModel> streamFreeTierPolicy() {
    return _service.streamFreeTierPolicy();
  }

  /// Save Free Tier Policy by Admin
  Future<bool> saveFreeTierPolicy(FreeTierPolicyModel policy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.saveFreeTierPolicy(policy);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Save Tenant Free Tier Policy by Admin
  Future<bool> saveTenantFreeTierPolicy(Map<String, dynamic> tenantData) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.saveTenantFreeTierPolicy(tenantData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Save House Owner Free Tier Policy by Admin
  Future<bool> saveOwnerFreeTierPolicy(Map<String, dynamic> ownerData) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.saveOwnerFreeTierPolicy(ownerData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Stream plans for Tenant
  Stream<List<SubscriptionPlanModel>> streamTenantPlans() {
    return _service.streamPlans(SubscriptionTargetRole.tenant);
  }

  /// Stream plans for House Owner
  Stream<List<SubscriptionPlanModel>> streamHouseOwnerPlans() {
    return _service.streamPlans(SubscriptionTargetRole.houseOwner);
  }

  /// Stream all plans for Admin
  Stream<List<SubscriptionPlanModel>> streamAllPlans() {
    return _service.streamAllPlans();
  }

  /// Stream user transaction history
  Stream<List<SubscriptionTransactionModel>> streamUserTransactions(String userId) {
    return _service.streamUserTransactions(userId);
  }

  /// Stream all transactions for Admin
  Stream<List<SubscriptionTransactionModel>> streamAllTransactions() {
    return _service.streamAllTransactions();
  }

  /// Unlock a property info for Tenant
  Future<bool> unlockProperty(BuildContext context, UserModel user, String propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSub = user.isSubscribed;
      await _service.unlockPropertyForUser(user.uid, propertyId, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasUnlockQuota) {
            deducted = true;
            return p.copyWith(unlocksUsed: p.unlocksUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedUnlocked = List<String>.from(user.unlockedPropertyIds)..add(propertyId);
      final updatedUser = user.copyWith(
        unlockedPropertyIds: updatedUnlocked,
        subscriptionUnlocksCount: isSub ? user.subscriptionUnlocksCount + 1 : user.subscriptionUnlocksCount,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );

      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unlock a demand contact info for House Owner
  Future<bool> unlockDemand(BuildContext context, UserModel user, String demandId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSub = user.isSubscribed;
      await _service.unlockDemandForUser(user.uid, demandId, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasUnlockQuota) {
            deducted = true;
            return p.copyWith(unlocksUsed: p.unlocksUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedUnlocked = List<String>.from(user.unlockedDemandIds);
      if (!updatedUnlocked.contains(demandId)) updatedUnlocked.add(demandId);

      final updatedUser = user.copyWith(
        unlockedDemandIds: updatedUnlocked,
        subscriptionUnlocksCount: isSub ? user.subscriptionUnlocksCount + 1 : user.subscriptionUnlocksCount,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );

      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unlock a property's sub-area location for Tenant
  Future<bool> unlockPropertySubArea(BuildContext context, UserModel user, String propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSub = user.isSubscribed;
      await _service.unlockPropertySubAreaForUser(user.uid, propertyId, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasSubAreaQuota) {
            deducted = true;
            return p.copyWith(subAreaUnlocksUsed: p.subAreaUnlocksUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedSubAreaUnlocked = List<String>.from(user.unlockedPropertySubAreaIds)..add(propertyId);
      final updatedUser = user.copyWith(
        unlockedPropertySubAreaIds: updatedSubAreaUnlocked,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );

      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unlock Full Photo Gallery of a property for Tenant
  Future<bool> unlockPhotoGallery(BuildContext context, UserModel user, String propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSub = user.isSubscribed;
      await _service.unlockPhotoGalleryForUser(user.uid, propertyId, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasPhotoGalleryQuota) {
            deducted = true;
            return p.copyWith(photoGalleryUsed: p.photoGalleryUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedUnlocked = List<String>.from(user.unlockedPhotoPropertyIds)..add(propertyId);
      final updatedUser = user.copyWith(
        unlockedPhotoPropertyIds: updatedUnlocked,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );

      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unlock a demand's sub-area location for House Owner
  Future<bool> unlockDemandSubArea(BuildContext context, UserModel user, String demandId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSub = user.isSubscribed;
      await _service.unlockDemandSubAreaForUser(user.uid, demandId, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasSubAreaQuota) {
            deducted = true;
            return p.copyWith(subAreaUnlocksUsed: p.subAreaUnlocksUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedSubAreaUnlocked = List<String>.from(user.unlockedDemandSubAreaIds)..add(demandId);
      final updatedUser = user.copyWith(
        unlockedDemandSubAreaIds: updatedSubAreaUnlocked,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );

      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Record radius search count
  Future<void> recordRadiusSearch(BuildContext context, UserModel user) async {
    try {
      final isSub = user.isSubscribed;
      await _service.incrementRadiusSearchCount(user.uid, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasNearbyQuota) {
            deducted = true;
            return p.copyWith(nearbySearchUsed: p.nearbySearchUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedUser = user.copyWith(
        radiusSearchCount: !isSub ? user.radiusSearchCount + 1 : user.radiusSearchCount,
        subscriptionNearbySearchCount: isSub ? user.subscriptionNearbySearchCount + 1 : user.subscriptionNearbySearchCount,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );
      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }
    } catch (_) {}
  }

  Future<void> incrementRadiusSearchCount(BuildContext context, UserModel user) async {
    await recordRadiusSearch(context, user);
  }

  /// Increment post count when publishing a listing or demand
  Future<void> incrementPostCount(BuildContext context, UserModel user) async {
    try {
      final isSub = user.isSubscribed;
      await _service.incrementPostCount(user.uid, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasPostQuota) {
            deducted = true;
            return p.copyWith(postsUsed: p.postsUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedUser = user.copyWith(
        subscriptionPostsCount: user.subscriptionPostsCount + 1,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );
      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }
    } catch (_) {}
  }

  /// Increment map direction count
  Future<void> incrementMapDirectionCount(BuildContext context, UserModel user) async {
    try {
      final isSub = user.isSubscribed;
      await _service.incrementMapDirectionCount(user.uid, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasMapDirectionsQuota) {
            deducted = true;
            return p.copyWith(mapDirectionsUsed: p.mapDirectionsUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedUser = user.copyWith(
        subscriptionMapDirectionsCount: user.subscriptionMapDirectionsCount + 1,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );
      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }
    } catch (_) {}
  }

  /// Increment AI query count
  Future<void> incrementAiQueryCount(BuildContext context, UserModel user) async {
    try {
      final isSub = user.isSubscribed;
      await _service.incrementAiQueryCount(user.uid, isSubscribed: isSub);

      List<UserSubscriptionPlan> updatedPlans = List.from(user.activeSubscriptionPlans);
      if (isSub && updatedPlans.isNotEmpty) {
        bool deducted = false;
        updatedPlans = updatedPlans.map((p) {
          if (!deducted && p.isPlanActive && p.hasAiQuota) {
            deducted = true;
            return p.copyWith(aiAssistantUsed: p.aiAssistantUsed + 1);
          }
          return p;
        }).toList();
      }

      final updatedUser = user.copyWith(
        aiAssistantQueryCount: user.aiAssistantQueryCount + 1,
        activeSubscriptionPlans: isSub ? updatedPlans : user.activeSubscriptionPlans,
      );
      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }
    } catch (_) {}
  }

  /// Execute bKash purchase and multi-plan activation / upgrade
  Future<bool> processPaymentAndActivate({
    required BuildContext context,
    required UserModel user,
    required SubscriptionPlanModel plan,
    required String transactionId,
    required String senderPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final newExpiry = now.add(Duration(days: plan.durationDays));

      await _service.purchaseSubscription(
        userId: user.uid,
        userEmail: user.email,
        userMobile: user.mobile.isNotEmpty ? user.mobile : senderPhone,
        plan: plan,
        transactionId: transactionId.trim().toUpperCase(),
        senderPhone: senderPhone.trim(),
      );

      final newPlanSnapshot = UserSubscriptionPlan(
        id: transactionId.trim().toUpperCase(),
        planId: plan.id,
        titleBn: plan.titleBn,
        titleEn: plan.titleEn,
        purchasedAt: now,
        expiresAt: newExpiry,
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

      final updatedPlans = List<UserSubscriptionPlan>.from(user.activeSubscriptionPlans)..add(newPlanSnapshot);
      final updatedUser = user.copyWith(
        activeSubscriptionPlans: updatedPlans,
        subscriptionPlanId: plan.id,
        subscriptionExpiryDate: newExpiry.toIso8601String(),
        subscriptionPostsCount: 0,
        subscriptionUnlocksCount: 0,
        subscriptionNearbySearchCount: 0,
        subscriptionMapDirectionsCount: 0,
        subscriptionMaxPosts: plan.maxPostsLimit,
        subscriptionMaxUnlocks: plan.unlockNumbersLimit,
        subscriptionCanAccessPhotos: plan.canAccessAdditionalPhotos,
        subscriptionMaxNearbySearches: plan.nearbySearchLimit,
        subscriptionMaxMapDirections: plan.mapDirectionsLimit,
        subscriptionMaxAiQueries: plan.aiAssistantLimit,
      );

      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin: Create New Plan
  Future<bool> createPlan(SubscriptionPlanModel plan) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createPlan(plan);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin: Update Plan or Offer
  Future<bool> updatePlanDetails(SubscriptionPlanModel plan) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updatePlan(plan);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin: Delete Plan
  Future<bool> deletePlan(String planId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deletePlan(planId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin: Restore or Seed the 6 default plans into Firestore
  Future<bool> restoreDefaultPlans() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.restoreDefaultPlans();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
