import 'package:flutter/material.dart';

enum AdminModule {
  dashboard,
  users,
  properties,
  categories,
  reports,
  faq,
  analytics,
  settings,
}

class AdminProvider extends ChangeNotifier {
  AdminModule _currentModule = AdminModule.dashboard;
  bool _isLoggedIn = false;

  AdminModule get currentModule => _currentModule;
  bool get isLoggedIn => _isLoggedIn;

  void changeModule(AdminModule module) {
    _currentModule = module;
    notifyListeners();
  }

  void login(String email, String password) {
    // For now, simple mock login
    if (email == 'admin@bashabondhu.com' && password == 'admin123') {
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  void logout() {
    _isLoggedIn = false;
    _currentModule = AdminModule.dashboard;
    notifyListeners();
  }
}
