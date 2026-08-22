import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../data/providers/admin_provider.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 90,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: AppColors.themeColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  isBn ? 'অ্যাডমিন প্যানেল' : 'Admin Panel',
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: isBn ? 'ড্যাশবোর্ড' : 'Dashboard',
                  module: AdminModule.dashboard,
                  isSelected: adminProvider.currentModule == AdminModule.dashboard,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.people_alt_rounded,
                  label: isBn ? 'ইউজার ম্যানেজমেন্ট' : 'Users',
                  module: AdminModule.users,
                  isSelected: adminProvider.currentModule == AdminModule.users,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.home_work_rounded,
                  label: isBn ? 'বাসাভাড়া বিজ্ঞাপন' : 'Properties',
                  module: AdminModule.properties,
                  isSelected: adminProvider.currentModule == AdminModule.properties,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.location_on_rounded,
                  label: isBn ? 'লোকেশন' : 'Locations',
                  module: AdminModule.locations,
                  isSelected: adminProvider.currentModule == AdminModule.locations,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.category_rounded,
                  label: isBn ? 'ক্যাটাগরি' : 'Categories',
                  module: AdminModule.categories,
                  isSelected: adminProvider.currentModule == AdminModule.categories,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.report_problem_rounded,
                  label: isBn ? 'অভিযোগ / রিপোর্ট' : 'Reports',
                  module: AdminModule.reports,
                  isSelected: adminProvider.currentModule == AdminModule.reports,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.question_answer_rounded,
                  label: isBn ? 'প্রশ্নোত্তর (FAQ)' : 'FAQs',
                  module: AdminModule.faq,
                  isSelected: adminProvider.currentModule == AdminModule.faq,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.analytics_rounded,
                  label: isBn ? 'অ্যানালিটিক্স' : 'Analytics',
                  module: AdminModule.analytics,
                  isSelected: adminProvider.currentModule == AdminModule.analytics,
                  isDark: isDark,
                ),
                _SidebarItem(
                  icon: Icons.settings_rounded,
                  label: isBn ? 'সেটিংস' : 'Settings',
                  module: AdminModule.settings,
                  isSelected: adminProvider.currentModule == AdminModule.settings,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(isBn ? 'লগআউট' : 'Logout', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => adminProvider.logout(),
          ),
          const SizedBox(height: 12),
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
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final AdminModule module;
  final bool isSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.themeColor : (isDark ? Colors.grey[400] : Colors.grey[600]), size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.themeColor : (isDark ? Colors.grey[300] : Colors.grey.shade800),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
        onTap: () => context.read<AdminProvider>().changeModule(module),
      ),
    );
  }
}
