import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/theme_provider.dart';
import '../../data/providers/admin_provider.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isBn = adminProvider.isBangla;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color sidebarBg = isDark ? const Color(0xFF131D1C) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF243432) : const Color(0xFFE2E9E7);

    return Material(
      color: sidebarBg,
      child: SizedBox(
        width: 260,
        child: Column(
          children: [
            // Admin Panel Branding Header
            Container(
              height: 80,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.themeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isBn ? 'অ্যাডমিন প্যানেল' : 'Admin Panel',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF142321),
                        ),
                      ),
                      Text(
                        'BashaBondhu System',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Modules Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                    icon: Icons.card_membership_rounded,
                    label: isBn ? 'সাবস্ক্রিপশন ও প্যাকেজ' : 'Subscriptions',
                    module: AdminModule.subscriptions,
                    isSelected: adminProvider.currentModule == AdminModule.subscriptions,
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

            // Bottom Actions (Theme Switcher & Logout)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Column(
                children: [
                  // Theme Mode Switcher Tile
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? Colors.amber : AppColors.themeColor,
                        size: 20,
                      ),
                      title: Text(
                        isDark ? (isBn ? 'লাইট মোড' : 'Light Mode') : (isBn ? 'ডার্ক মোড' : 'Dark Mode'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                        ),
                      ),
                      onTap: () {
                        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                        themeProvider.changeThemeMode(newMode);
                      },
                    ),
                  ),

                  // Logout Tile
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      title: Text(
                        isBn ? 'লগআউট' : 'Logout',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => adminProvider.logout(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected ? AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            icon,
            color: isSelected ? AppColors.themeColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
            size: 20,
          ),
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
      ),
    );
  }
}
