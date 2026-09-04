import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  static const String _kCachedUserKey = 'cached_user_profile';
  static const String _kCachedRoleKey = 'cached_user_role';

  UserModel? _user;
  bool _isLoading = false;
  final Completer<void> _initCompleter = Completer<void>();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGuest => _user == null;

  /// Await this future in SplashScreen to ensure user role is loaded before navigating
  Future<void> ensureInitialized() => _initCompleter.future;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    // 1. Fast local cache load (Frame 0 instantaneous memory restoration)
    await _loadFromCache();

    // 2. Synchronize with Firebase Auth session
    final currentFbUser = _auth.currentUser;
    if (currentFbUser != null) {
      // If cached profile matched current user, notify listeners immediately for instant UI
      if (_user != null && _user!.uid == currentFbUser.uid) {
        notifyListeners();
      }
      // Refresh latest data from Firestore in background
      await fetchUserData(currentFbUser.uid);
    } else {
      _user = null;
      await _clearCache();
    }

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    notifyListeners();

    // 3. Keep listening to live auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
        await _clearCache();
        notifyListeners();
      } else {
        if (_user == null || _user!.uid != firebaseUser.uid) {
          await fetchUserData(firebaseUser.uid);
        }
      }
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    });
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_kCachedUserKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(cachedJson);
        _user = UserModel.fromMap(data);
        debugPrint('💾 Loaded user profile from local cache: ${_user?.email} (${_user?.userType})');
      }
    } catch (e) {
      debugPrint('Error loading cached user: $e');
    }
  }

  Future<void> _saveToCache(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(user.toMap());
      await prefs.setString(_kCachedUserKey, jsonString);
      await prefs.setString(_kCachedRoleKey, user.userType);
      debugPrint('💾 Saved user profile to local cache: ${user.email} (${user.userType})');
    } catch (e) {
      debugPrint('Error saving user to cache: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedUserKey);
      await prefs.remove(_kCachedRoleKey);
      debugPrint('💾 Cleared local user cache');
    } catch (e) {
      debugPrint('Error clearing cached user: $e');
    }
  }

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  Future<void> fetchUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Initial immediate fetch
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        if (!data.containsKey('uid') || (data['uid'] as String).isEmpty) {
          data['uid'] = uid;
        }
        _user = UserModel.fromMap(data);
        await _saveToCache(_user!);
      }

      // 2. Real-time stream subscription so any admin verification/unverification updates live instantly
      _userSubscription?.cancel();
      _userSubscription = _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final liveData = Map<String, dynamic>.from(snapshot.data() as Map);
          if (!liveData.containsKey('uid') || (liveData['uid'] as String).isEmpty) {
            liveData['uid'] = uid;
          }
          _user = UserModel.fromMap(liveData);
          _saveToCache(_user!);
          notifyListeners();
          debugPrint('🔄 Real-time user update received: ${_user?.fullName} | Status: ${_user?.verificationStatus}');
        }
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile in Firestore, in local state, and in local disk cache
  Future<void> updateUserProfile(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));
      _user = updatedUser;
      await _saveToCache(updatedUser);
      debugPrint('✅ User profile updated successfully: ${updatedUser.uid}');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    _saveToCache(updatedUser);
    notifyListeners();
  }

  void clearUser() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = null;
    _clearCache();
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _userSubscription = null;
    super.dispose();
  }
}
