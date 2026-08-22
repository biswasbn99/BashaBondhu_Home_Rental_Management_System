import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/theme_provider.dart';
import '../../data/providers/admin_provider.dart';
import '../widgets/admin_sidebar.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    final Color scaffoldBg = isDark ? const Color(0xFF0E1615) : const Color(0xFFF4F7F6);
    final Color headerBg = isDark ? const Color(0xFF162120) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF243432) : const Color(0xFFE2E9E7);

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: !isDesktop ? const Drawer(child: AdminSidebar()) : null,
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(),
          if (isDesktop) VerticalDivider(width: 1, thickness: 1, color: borderColor),
          Expanded(
            child: Column(
              children: [
                // Top Global Navigation Bar
                Material(
                  color: headerBg,
                  elevation: isDark ? 0 : 0.5,
                  child: Container(
                    height: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Drawer Button (on mobile) or Module Title Breadcrumb (on desktop)
                        Row(
                          children: [
                            if (!isDesktop)
                              Builder(
                                builder: (ctx) => IconButton(
                                  icon: const Icon(Icons.menu_rounded),
                                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                                  tooltip: 'Open Menu',
                                ),
                              ),
                            if (!isDesktop) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.dashboard_customize_rounded, size: 16, color: AppColors.themeColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getModuleTitle(adminProvider.currentModule, isBn),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.themeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Right: Theme Mode Switcher, Language Switcher, and Admin Profile
                        Row(
                          children: [
                            // Language Switcher Button
                            InkWell(
                              onTap: () => adminProvider.toggleLanguage(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF202E2C) : const Color(0xFFEBF2F0),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.language_rounded, size: 16, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      isBn ? 'বাংলা' : 'EN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Dark / Light Mode Switcher Toggle Button
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF202E2C) : const Color(0xFFEBF2F0),
                                padding: const EdgeInsets.all(8),
                              ),
                              icon: Icon(
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                color: isDark ? Colors.amber : AppColors.themeColor,
                                size: 20,
                              ),
                              tooltip: isDark
                                  ? (isBn ? 'লাইট মোড চালু করুন' : 'Switch to Light Mode')
                                  : (isBn ? 'ডার্ক মোড চালু করুন' : 'Switch to Dark Mode'),
                              onPressed: () {
                                final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                                themeProvider.changeThemeMode(newMode);
                              },
                            ),
                            const SizedBox(width: 12),

                            // Admin Profile Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF202E2C) : const Color(0xFFEBF2F0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.themeColor,
                                    child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    adminProvider.adminName ?? 'Super Admin',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Module Body
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getModuleTitle(AdminModule module, bool isBn) {
    switch (module) {
      case AdminModule.dashboard:
        return isBn ? 'ড্যাশবোর্ড' : 'Dashboard';
      case AdminModule.users:
        return isBn ? 'ইউজার ম্যানেজমেন্ট' : 'User Management';
      case AdminModule.properties:
        return isBn ? 'বাসাভাড়া বিজ্ঞাপন' : 'Property Management';
      case AdminModule.locations:
        return isBn ? 'লোকেশন' : 'Location Management';
      case AdminModule.categories:
        return isBn ? 'ক্যাটাগরি' : 'Category Management';
      case AdminModule.reports:
        return isBn ? 'রিপোর্ট ও অভিযোগ' : 'Reports Management';
      case AdminModule.faq:
        return isBn ? 'প্রশ্নোত্তর (FAQ)' : 'FAQ Management';
      case AdminModule.analytics:
        return isBn ? 'অ্যানালিটিক্স' : 'Analytics & Insights';
      case AdminModule.settings:
        return isBn ? 'সিস্টেম সেটিংস' : 'System Settings';
    }
  }
}
