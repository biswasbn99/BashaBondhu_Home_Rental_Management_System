import 'package:cloud_firestore/cloud_firestore.dart';
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

  AdminModule _currentModule = AdminModule.dashboard;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isBangla = false; // Default language is English as requested
  String? _adminName;
  String? _adminEmail;

  AdminModule get currentModule => _currentModule;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isBangla => _isBangla;
  String? get adminName => _adminName;
  String? get adminEmail => _adminEmail;

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
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Query Firestore 'admins' collection
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
          notifyListeners();
          return true;
        }
      }

      // Check default fallback
      if (cleanEmail == 'admin1@gmail.com' && cleanPassword == '1234567') {
        _isLoggedIn = true;
        _adminEmail = cleanEmail;
        _adminName = 'Super Admin';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Admin login error: $e');
      if (cleanEmail == 'admin1@gmail.com' && cleanPassword == '1234567') {
        _isLoggedIn = true;
        _adminEmail = cleanEmail;
        _adminName = 'Super Admin';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _adminEmail = null;
    _adminName = null;
    _currentModule = AdminModule.dashboard;
    notifyListeners();
  }
}
