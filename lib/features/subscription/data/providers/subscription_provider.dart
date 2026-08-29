import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import '../models/subscription_model.dart';
import '../services/subscription_firestore_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionFirestoreService _service = SubscriptionFirestoreService();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SubscriptionProvider() {
    _service.seedDefaultPlansIfEmpty();
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
      await _service.unlockPropertyForUser(user.uid, propertyId);
      
      // Update local UserModel state in UserProvider
      final updatedUnlocked = List<String>.from(user.unlockedPropertyIds)..add(propertyId);
      final updatedUser = user.copyWith(unlockedPropertyIds: updatedUnlocked);
      
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
      await _service.unlockDemandForUser(user.uid, demandId);

      // Update local UserModel state in UserProvider
      final updatedUnlocked = List<String>.from(user.unlockedDemandIds)..add(demandId);
      final updatedUser = user.copyWith(unlockedDemandIds: updatedUnlocked);

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
      await _service.incrementRadiusSearchCount(user.uid);
      final updatedUser = user.copyWith(radiusSearchCount: user.radiusSearchCount + 1);
      if (context.mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }
    } catch (_) {}
  }

  Future<void> incrementRadiusSearchCount(BuildContext context, UserModel user) async {
    await recordRadiusSearch(context, user);
  }

  /// Execute bKash purchase and activation
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
      await _service.purchaseSubscription(
        userId: user.uid,
        userEmail: user.email,
        userMobile: user.mobile.isNotEmpty ? user.mobile : senderPhone,
        plan: plan,
        transactionId: transactionId.trim().toUpperCase(),
        senderPhone: senderPhone.trim(),
      );

      // Update local UserModel with new expiry
      final newExpiry = DateTime.now().add(Duration(days: plan.durationDays));
      final updatedUser = user.copyWith(
        subscriptionPlanId: plan.id,
        subscriptionExpiryDate: newExpiry.toIso8601String(),
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
}

