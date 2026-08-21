import 'package:bashabondhu_home_rental_management_system/features/admin/data/providers/admin_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/layout/admin_layout.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/admin_login_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/property_management_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/user_management_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/location_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      default:
        return Center(
          child: Text('Module ${module.name} is under development'),
        );
    }
  }
}
