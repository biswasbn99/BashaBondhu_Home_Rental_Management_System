import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/theme_provider.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isBn = adminProvider.isBangla;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color sidebarBg = isDark ? const Color(0xFF0C1917) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1A332E) : const Color(0xFFE2E8F0);

    return StreamBuilder<List<UserModel>>(
      stream: AdminFirestoreService().streamAllUsers(),
      builder: (context, snapshot) {
        final pendingCount = (snapshot.data ?? []).where((u) => u.isVerificationPending).length;

        return Material(
          color: sidebarBg,
          child: SizedBox(
            width: 270,
            child: Column(
              children: [
                // Admin Panel Branding Header
                Container(
                  height: 86,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 1.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2DD4BF), AppColors.themeColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.themeColor.withValues(alpha: isDark ? 0.4 : 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isBn ? 'অ্যাডমিন প্যানেল' : 'Admin Portal',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16.5,
                                letterSpacing: -0.2,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'BashaBondhu System',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Modules Navigation List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                        badge: pendingCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  pendingCount > 99 ? '99+' : pendingCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            : null,
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
                    icon: Icons.policy_rounded,
                    label: isBn ? 'আইনি পলিসি ও শর্তাবলী' : 'Legal Policies',
                    module: AdminModule.policies,
                    isSelected: adminProvider.currentModule == AdminModule.policies,
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
                  const SizedBox(height: 12),
                  // AI Assistant Item
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AIAssistantScreen.name);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00A896), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00A896).withValues(alpha: isDark ? 0.4 : 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isBn ? 'এআই অ্যাডমিন সহকারী' : 'AI Admin Assistant',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Actions (Theme Switcher & Logout)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1.4)),
              ),
              child: Column(
                children: [
                  // Theme Mode Switcher Tile
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? Colors.amber : AppColors.themeColor,
                        size: 20,
                      ),
                      title: Text(
                        isDark ? (isBn ? 'লাইট মোড' : 'Light Mode') : (isBn ? 'ডার্ক মোড' : 'Dark Mode'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      title: Text(
                        isBn ? 'লগআউট' : 'Logout',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
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
  },
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
    this.badge,
  });

  final IconData icon;
  final String label;
  final AdminModule module;
  final bool isSelected;
  final bool isDark;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: isSelected
            ? (isDark
                ? AppColors.themeColor.withValues(alpha: 0.25)
                : AppColors.themeColor.withValues(alpha: 0.12))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.read<AdminProvider>().changeModule(module),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppColors.themeColor.withValues(alpha: isDark ? 0.5 : 0.3),
                      width: 1.2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? (isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.themeColor)
                          : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  badge!,
                  const SizedBox(width: 6),
                ],
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF2DD4BF) : AppColors.themeColor).withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
