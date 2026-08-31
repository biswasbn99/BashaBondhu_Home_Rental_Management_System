import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AdminModule {
  dashboard,
  users,
  properties,
  subscriptions,
  locations,
  categories,
  reports,
  policies,
  faq,
  analytics,
  settings,
}

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AdminModule _currentModule = AdminModule.dashboard;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isBangla = false; // Default language is English as requested
  String? _adminName;
  String? _adminEmail;
  String? _lastErrorMessage;

  AdminModule get currentModule => _currentModule;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isBangla => _isBangla;
  String? get adminName => _adminName;
  String? get adminEmail => _adminEmail;
  String? get lastErrorMessage => _lastErrorMessage;

  void changeModule(AdminModule module) {
    _currentModule = module;
    notifyListeners();
  }

  void toggleLanguage() {
    _isBangla = !_isBangla;
    notifyListeners();
  }

  void setLanguage(bool isBangla) {
    _isBangla = isBangla;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _lastErrorMessage = 'Please enter both email and password';
      return false;
    }

    _isLoading = true;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      // 1. Try Firebase Authentication first
      UserCredential? credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
      } on FirebaseAuthException catch (authErr) {
        debugPrint('Firebase Auth Sign-In Error: ${authErr.code} - ${authErr.message}');
        
        // Auto-provision default admin if not created in Firebase Auth yet
        if ((cleanEmail == 'biswashridoy528@gmail.com' || cleanEmail == 'admin1@gmail.com') &&
            cleanPassword == '1234567' &&
            (authErr.code == 'user-not-found' || authErr.code == 'invalid-credential')) {
          try {
            credential = await _auth.createUserWithEmailAndPassword(
              email: cleanEmail,
              password: cleanPassword,
            );
            debugPrint('✅ Admin account auto-created in Firebase Auth: $cleanEmail');
          } catch (createErr) {
            debugPrint('Admin create in Firebase Auth error: $createErr');
          }
        } else {
          _lastErrorMessage = authErr.code == 'invalid-credential' || authErr.code == 'wrong-password'
              ? 'ভুল ইমেইল বা পাসওয়ার্ড! সঠিক তথ্য দিয়ে চেষ্টা করুন।'
              : (authErr.message ?? 'লগইন ব্যর্থ হয়েছে।');
        }
      }

      // 2. If Firebase Auth succeeded
      if (credential != null && credential.user != null) {
        final uid = credential.user!.uid;

        // Check if admin permission is authorized
        bool isAuthorizedAdmin = cleanEmail == 'biswashridoy528@gmail.com' ||
            cleanEmail == 'admin1@gmail.com';

        if (!isAuthorizedAdmin) {
          final adminDoc = await _firestore.collection('admins').doc(cleanEmail).get();
          if (adminDoc.exists) {
            isAuthorizedAdmin = true;
          } else {
            final userDoc = await _firestore.collection('users').doc(uid).get();
            if (userDoc.exists && userDoc.data()?['userType'] == 'Admin') {
              isAuthorizedAdmin = true;
            }
          }
        }

        if (isAuthorizedAdmin) {
          // Sync admin record in Firestore
          await _firestore.collection('admins').doc(cleanEmail).set({
            'email': cleanEmail,
            'uid': uid,
            'name': 'Super Admin',
            'role': 'super_admin',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          _isLoggedIn = true;
          _adminEmail = cleanEmail;
          _adminName = 'Super Admin';
          _isLoading = false;
          _lastErrorMessage = null;
          notifyListeners();
          return true;
        } else {
          _isLoading = false;
          _lastErrorMessage = 'এই অ্যাকাউন্টটি অ্যাডমিন হিসেবে অনুমোদিত নয়।';
          notifyListeners();
          return false;
        }
      }

      // 3. Fallback: Check Firestore 'admins' collection directly
      final querySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final storedPassword = data['password']?.toString() ?? '';

        if (storedPassword == cleanPassword) {
          _isLoggedIn = true;
          _adminEmail = cleanEmail;
          _adminName = data['name']?.toString() ?? 'Admin';
          _isLoading = false;
          _lastErrorMessage = null;
          notifyListeners();
          return true;
        }
      }

      // 4. Fallback for offline/test super admin
      if ((cleanEmail == 'biswashridoy528@gmail.com' || cleanEmail == 'admin1@gmail.com') &&
          cleanPassword == '1234567') {
        _isLoggedIn = true;
        _adminEmail = cleanEmail;
        _adminName = 'Super Admin';
        _isLoading = false;
        _lastErrorMessage = null;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _lastErrorMessage ??= 'ভুল ইমেইল বা পাসওয়ার্ড! সঠিক তথ্য দিন।';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Admin login general error: $e');
      if ((cleanEmail == 'biswashridoy528@gmail.com' || cleanEmail == 'admin1@gmail.com') &&
          cleanPassword == '1234567') {
        _isLoggedIn = true;
        _adminEmail = cleanEmail;
        _adminName = 'Super Admin';
        _isLoading = false;
        _lastErrorMessage = null;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      _lastErrorMessage = 'লগইন করার সময় একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _auth.signOut();
    _isLoggedIn = false;
    _adminEmail = null;
    _adminName = null;
    _currentModule = AdminModule.dashboard;
    notifyListeners();
  }
}
