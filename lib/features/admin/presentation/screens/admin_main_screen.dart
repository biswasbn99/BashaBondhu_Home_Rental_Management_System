import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/admin_provider.dart';
import '../layout/admin_layout.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';
import 'admin_policy_management_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_subscription_management_screen.dart';
import 'analytics_screen.dart';
import 'faq_management_screen.dart';
import 'location_management_screen.dart';
import 'property_management_screen.dart';
import 'reports_management_screen.dart';
import 'user_management_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});
  static const String name = '/admin';

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  final Set<AdminModule> _loadedModules = {AdminModule.dashboard};

  @override
  void initState() {
    super.initState();
    // Warm up high-frequency modules in the background idle window right after Dashboard renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _loadedModules.addAll([
              AdminModule.users,
              AdminModule.properties,
              AdminModule.subscriptions,
            ]);
          });
        }
      });
    });
  }

  Widget _buildModuleView(AdminModule module) {
    switch (module) {
      case AdminModule.dashboard:
        return const AdminDashboardView();
      case AdminModule.users:
        return const UserManagementView();
      case AdminModule.properties:
        return const PropertyManagementView();
      case AdminModule.subscriptions:
        return const AdminSubscriptionManagementView();
      case AdminModule.locations:
        return const LocationManagementView();
      case AdminModule.reports:
        return const ReportsManagementView();
      case AdminModule.policies:
        return const AdminPolicyManagementView();
      case AdminModule.faq:
        return const FaqManagementView();
      case AdminModule.analytics:
        return const AnalyticsView();
      case AdminModule.settings:
        return const AdminSettingsView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AdminProvider, bool>((p) => p.isLoggedIn);

    if (!isLoggedIn) {
      return const AdminLoginScreen();
    }

    final currentModule = context.select<AdminProvider, AdminModule>((p) => p.currentModule);
    _loadedModules.add(currentModule);

    return AdminLayout(
      child: IndexedStack(
        index: AdminModule.values.indexOf(currentModule),
        children: AdminModule.values.map((module) {
          if (_loadedModules.contains(module)) {
            return _buildModuleView(module);
          } else {
            return const SizedBox.shrink();
          }
        }).toList(),
      ),
    );
  }
}
