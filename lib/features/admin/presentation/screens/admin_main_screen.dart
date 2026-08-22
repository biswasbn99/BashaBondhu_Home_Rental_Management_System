import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/admin_provider.dart';
import '../layout/admin_layout.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';
import 'admin_settings_screen.dart';
import 'analytics_screen.dart';
import 'category_management_screen.dart';
import 'faq_management_screen.dart';
import 'location_management_screen.dart';
import 'property_management_screen.dart';
import 'reports_management_screen.dart';
import 'user_management_screen.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});
  static const String name = '/admin';

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    if (!adminProvider.isLoggedIn) {
      return const AdminLoginScreen();
    }

    return AdminLayout(
      child: _buildBody(adminProvider.currentModule),
    );
  }

  Widget _buildBody(AdminModule module) {
    switch (module) {
      case AdminModule.dashboard:
        return const AdminDashboardView();
      case AdminModule.users:
        return const UserManagementView();
      case AdminModule.properties:
        return const PropertyManagementView();
      case AdminModule.locations:
        return const LocationManagementView();
      case AdminModule.categories:
        return const CategoryManagementView();
      case AdminModule.reports:
        return const ReportsManagementView();
      case AdminModule.faq:
        return const FaqManagementView();
      case AdminModule.analytics:
        return const AnalyticsView();
      case AdminModule.settings:
        return const AdminSettingsView();
    }
  }
}
