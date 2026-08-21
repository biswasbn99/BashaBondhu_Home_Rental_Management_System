import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/data/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final theme = Theme.of(context);

    return Container(
      width: 250,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 100,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.themeColor, size: 30),
                const SizedBox(width: 10),
                Text(
                  'Admin Panel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.themeColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  module: AdminModule.dashboard,
                  isSelected: adminProvider.currentModule == AdminModule.dashboard,
                ),
                _SidebarItem(
                  icon: Icons.people_rounded,
                  label: 'Users',
                  module: AdminModule.users,
                  isSelected: adminProvider.currentModule == AdminModule.users,
                ),
                _SidebarItem(
                  icon: Icons.home_work_rounded,
                  label: 'Properties',
                  module: AdminModule.properties,
                  isSelected: adminProvider.currentModule == AdminModule.properties,
                ),
                _SidebarItem(
                  icon: Icons.location_on_rounded,
                  label: 'Locations',
                  module: AdminModule.locations,
                  isSelected: adminProvider.currentModule == AdminModule.locations,
                ),
                _SidebarItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  module: AdminModule.categories,
                  isSelected: adminProvider.currentModule == AdminModule.categories,
                ),
                _SidebarItem(
                  icon: Icons.report_problem_rounded,
                  label: 'Reports',
                  module: AdminModule.reports,
                  isSelected: adminProvider.currentModule == AdminModule.reports,
                ),
                _SidebarItem(
                  icon: Icons.question_answer_rounded,
                  label: 'FAQs',
                  module: AdminModule.faq,
                  isSelected: adminProvider.currentModule == AdminModule.faq,
                ),
                _SidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  module: AdminModule.analytics,
                  isSelected: adminProvider.currentModule == AdminModule.analytics,
                ),
                _SidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  module: AdminModule.settings,
                  isSelected: adminProvider.currentModule == AdminModule.settings,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => adminProvider.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.module,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final AdminModule module;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.themeColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.themeColor : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.themeColor : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () => context.read<AdminProvider>().changeModule(module),
      ),
    );
  }
}
