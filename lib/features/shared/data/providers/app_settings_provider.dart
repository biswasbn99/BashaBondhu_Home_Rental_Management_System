import 'dart:async';
import 'package:flutter/material.dart';

import '../../../admin/data/services/admin_firestore_service.dart';

/// Central provider that keeps system settings synchronized in real-time
/// across Admin, Tenant, and House Owner interfaces.
class AppSettingsProvider extends ChangeNotifier {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  StreamSubscription<Map<String, dynamic>>? _settingsSubscription;

  String _appName = 'BashaBondhu Home Rental';
  String _logoUrl = '';
  String _bannerNotice = 'স্বাগতম বাসাবন্ধু হোম রেন্টাল ম্যানেজমেন্ট সিস্টেমে!';
  String _bannerNoticeEn = 'Welcome to BashaBondhu Home Rental Management System!';
  String _helpline = '+880 1700-000000';
  String _supportEmail = 'support@bashabondhu.com';
  String _officeAddress = 'House 12, Road 5, Dhanmondi, Dhaka - 1205';
  String _facebookUrl = 'https://facebook.com/bashabondhu';
  String _youtubeUrl = 'https://youtube.com/@bashabondhu';
  String _whatsappNumber = '+8801700000000';
  String _websiteUrl = 'https://bashabondhu.com';
  bool _autoApprovalEnabled = true;
  bool _requireVerifiedTenantForDemands = false;
  bool _requireVerifiedOwnerForProperties = false;
  bool _isLoaded = false;

  AppSettingsProvider() {
    _listenToSettings();
  }

  bool _parseBool(dynamic val, {bool defaultValue = false}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    if (val is num) return val != 0;
    return defaultValue;
  }

  void _listenToSettings() {
    _settingsSubscription = _adminService.streamSettings().listen(
      (data) {
        _appName = data['appName']?.toString() ?? _appName;
        _logoUrl = data['logoUrl']?.toString() ?? _logoUrl;
        _bannerNotice = data['bannerNotice']?.toString() ?? _bannerNotice;
        _bannerNoticeEn = data['bannerNoticeEn']?.toString() ?? _bannerNoticeEn;
        _helpline = data['helpline']?.toString() ?? _helpline;
        _supportEmail = data['supportEmail']?.toString() ?? _supportEmail;
        _officeAddress = data['officeAddress']?.toString() ?? _officeAddress;
        _facebookUrl = data['facebookUrl']?.toString() ?? _facebookUrl;
        _youtubeUrl = data['youtubeUrl']?.toString() ?? _youtubeUrl;
        _whatsappNumber = data['whatsappNumber']?.toString() ?? _whatsappNumber;
        _websiteUrl = data['websiteUrl']?.toString() ?? _websiteUrl;
        _autoApprovalEnabled = _parseBool(data['autoApprovalEnabled'], defaultValue: true);
        _requireVerifiedTenantForDemands =
            _parseBool(data['requireVerifiedTenantForDemands'], defaultValue: false);
        _requireVerifiedOwnerForProperties =
            _parseBool(data['requireVerifiedOwnerForProperties'], defaultValue: false);
        _isLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('⚠️ Error streaming app settings: $e');
      },
    );
  }

  // Getters
  String get appName => _appName;
  String get logoUrl => _logoUrl;
  String get bannerNotice => _bannerNotice;
  String get bannerNoticeEn => _bannerNoticeEn;
  String get helpline => _helpline;
  String get supportEmail => _supportEmail;
  String get officeAddress => _officeAddress;
  String get facebookUrl => _facebookUrl;
  String get youtubeUrl => _youtubeUrl;
  String get whatsappNumber => _whatsappNumber;
  String get websiteUrl => _websiteUrl;
  bool get autoApprovalEnabled => _autoApprovalEnabled;
  bool get requireVerifiedTenantForDemands => _requireVerifiedTenantForDemands;
  bool get requireVerifiedOwnerForProperties => _requireVerifiedOwnerForProperties;
  bool get isLoaded => _isLoaded;

  /// Returns localized announcement banner text according to language code.
  String getBannerNotice(String langCode) {
    if (langCode == 'bn') {
      return _bannerNotice.isNotEmpty ? _bannerNotice : _bannerNoticeEn;
    } else {
      return _bannerNoticeEn.isNotEmpty ? _bannerNoticeEn : _bannerNotice;
    }
  }

  /// Updates settings directly in Firestore.
  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _adminService.saveSettings(data);
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
