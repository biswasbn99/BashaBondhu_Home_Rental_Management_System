import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/providers/theme_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';
import '../../../shared/data/models/app_notification_model.dart';
import '../../../shared/data/services/notification_firestore_service.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';
import '../widgets/admin_post_details_dialog.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_user_posts_dialog.dart';

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

    final Color scaffoldBg = isDark ? const Color(0xFF081210) : const Color(0xFFF1F5F9);
    final Color headerBg = isDark ? const Color(0xFF0E1F1C) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1A332E) : const Color(0xFFE2E8F0);

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
                  elevation: isDark ? 0 : 1,
                  shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.06),
                  child: Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor, width: 1.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Drawer Button (on mobile) or Module Title Breadcrumb (on desktop)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isDesktop)
                                Builder(
                                  builder: (ctx) => IconButton(
                                    icon: const Icon(Icons.menu_rounded),
                                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                                    tooltip: 'Open Menu',
                                  ),
                                ),
                              if (!isDesktop) const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [AppColors.themeColor.withValues(alpha: 0.25), AppColors.themeColor.withValues(alpha: 0.12)]
                                          : [AppColors.themeColor.withValues(alpha: 0.14), AppColors.themeColor.withValues(alpha: 0.06)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.themeColor.withValues(alpha: isDark ? 0.45 : 0.25),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getModuleIcon(adminProvider.currentModule), size: 18, color: AppColors.themeColor),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _getModuleTitle(adminProvider.currentModule, isBn),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: AppColors.themeColor,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right: Language Switcher, Theme Mode Switcher, and Admin Profile
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Language Switcher Button
                            const LanguageActionButton(),
                            const SizedBox(width: 8),

                            // Notification Bell Icon with Pending Reclaim Appeals, Verification Requests & Post Activities
                            StreamBuilder<List<UserModel>>(
                              stream: AdminFirestoreService().streamAllUsers(),
                              builder: (context, userSnap) {
                                return StreamBuilder<List<AppNotificationModel>>(
                                  stream: NotificationFirestoreService().streamAdminNotifications(),
                                  builder: (context, notifSnap) {
                                    final allUsers = userSnap.data ?? [];
                                    final allNotifs = notifSnap.data ?? [];
                                    final pendingAppeals = allUsers.where((u) => u.appealStatus == 'pending').toList();
                                    final pendingVerifications = allUsers.where((u) => u.isVerificationPending).toList();
                                    final unreadNotifs = allNotifs.where((n) => !n.isRead).toList();
                                    final count = unreadNotifs.length + pendingAppeals.length + pendingVerifications.length;

                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: isDark ? const Color(0xFF162B27) : const Color(0xFFF1F5F9),
                                            padding: const EdgeInsets.all(9),
                                            side: BorderSide(color: borderColor, width: 1.2),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: Icon(
                                            count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                            color: count > 0
                                                ? (pendingAppeals.isNotEmpty ? Colors.amber.shade700 : AppColors.themeColor)
                                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                            size: 20,
                                          ),
                                          tooltip: isBn ? 'নোটিফিকেশন ($count)' : 'Notifications ($count)',
                                          onPressed: () => _showAdminNotificationsModal(
                                            context,
                                            postNotifications: allNotifs,
                                            pendingAppeals: pendingAppeals,
                                            pendingVerifications: pendingVerifications,
                                            isBn: isBn,
                                            isDark: isDark,
                                            adminProvider: adminProvider,
                                          ),
                                        ),
                                        if (count > 0)
                                          Positioned(
                                            top: -3,
                                            right: -3,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: pendingAppeals.isNotEmpty ? Colors.orange.shade800 : const Color(0xFFEF4444),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: headerBg, width: 1.5),
                                              ),
                                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                              alignment: Alignment.center,
                                              child: Text(
                                                count > 99 ? '99+' : count.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 8),

                            // Dark / Light Mode Switcher Toggle Button
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF162B27) : const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.all(9),
                                side: BorderSide(color: borderColor, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                            // Admin Profile Chip (shown on screens > 620px)
                            if (MediaQuery.of(context).size.width > 620) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF162B27) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: borderColor, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF2DD4BF), AppColors.themeColor],
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'A',
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          adminProvider.adminName ?? 'Super Admin',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF22C55E),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isBn ? 'অনলাইন' : 'Active',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  IconData _getModuleIcon(AdminModule module) {
    switch (module) {
      case AdminModule.dashboard:
        return Icons.dashboard_rounded;
      case AdminModule.users:
        return Icons.people_alt_rounded;
      case AdminModule.properties:
        return Icons.home_work_rounded;
      case AdminModule.subscriptions:
        return Icons.card_membership_rounded;
      case AdminModule.locations:
        return Icons.location_on_rounded;
      case AdminModule.categories:
        return Icons.category_rounded;
      case AdminModule.reports:
        return Icons.report_problem_rounded;
      case AdminModule.policies:
        return Icons.policy_rounded;
      case AdminModule.faq:
        return Icons.question_answer_rounded;
      case AdminModule.analytics:
        return Icons.analytics_rounded;
      case AdminModule.settings:
        return Icons.settings_rounded;
    }
  }

  String _getModuleTitle(AdminModule module, bool isBn) {
    switch (module) {
      case AdminModule.dashboard:
        return isBn ? 'ড্যাশবোর্ড' : 'Dashboard';
      case AdminModule.users:
        return isBn ? 'ইউজার ম্যানেজমেন্ট' : 'User Management';
      case AdminModule.properties:
        return isBn ? 'বাসাভাড়া বিজ্ঞাপন' : 'Property Management';
      case AdminModule.subscriptions:
        return isBn ? 'সাবস্ক্রিপশন ও অফার ম্যানেজমেন্ট' : 'Subscription & Offer Management';
      case AdminModule.locations:
        return isBn ? 'লোকেশন' : 'Location Management';
      case AdminModule.categories:
        return isBn ? 'ক্যাটাগরি' : 'Category Management';
      case AdminModule.reports:
        return isBn ? 'রিপোর্ট ও অভিযোগ' : 'Reports Management';
      case AdminModule.policies:
        return isBn ? 'আইনি পলিসি ও শর্তাবলী' : 'Legal Policies & Terms';
      case AdminModule.faq:
        return isBn ? 'প্রশ্নোত্তর (FAQ)' : 'FAQ Management';
      case AdminModule.analytics:
        return isBn ? 'অ্যানালিটিক্স' : 'Analytics & Insights';
      case AdminModule.settings:
        return isBn ? 'সিস্টেম সেটিংস' : 'System Settings';
    }
  }

  void _showAdminNotificationsModal(
    BuildContext context, {
    required List<AppNotificationModel> postNotifications,
    required List<UserModel> pendingAppeals,
    required List<UserModel> pendingVerifications,
    required bool isBn,
    required bool isDark,
    required AdminProvider adminProvider,
  }) {
    final modalBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final cardBg = isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final adminService = AdminFirestoreService();
    final notifService = NotificationFirestoreService();

    int selectedTab = postNotifications.any((n) => !n.isRead)
        ? 0
        : (pendingAppeals.isNotEmpty ? 1 : (pendingVerifications.isNotEmpty ? 2 : 0));
    int postActivitySubFilter = postNotifications.any((n) => !n.isRead) ? 0 : 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final unreadPostCount = postNotifications.where((n) => !n.isRead).length;

          return Dialog(
            backgroundColor: modalBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor, width: 1.2),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 750, maxHeight: 760),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: AppColors.themeColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isBn ? 'অ্যাডমিন নোটিফিকেশন সেন্টার' : 'Admin Notification Center',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: subtitleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF081210) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedTab = 0),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedTab == 0
                                    ? (isDark ? const Color(0xFF162B27) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dynamic_feed_rounded,
                                    size: 15,
                                    color: selectedTab == 0
                                        ? (unreadPostCount > 0 ? const Color(0xFF0284C7) : AppColors.themeColor)
                                        : subtitleColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      isBn
                                          ? 'পোস্ট কার্যক্রম (${postNotifications.length})'
                                          : 'Post Activity (${postNotifications.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: selectedTab == 0 ? FontWeight.w900 : FontWeight.w600,
                                        color: selectedTab == 0 ? titleColor : subtitleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedTab = 1),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedTab == 1
                                    ? (isDark ? const Color(0xFF162B27) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.balance_rounded,
                                    size: 15,
                                    color: selectedTab == 1
                                        ? (pendingAppeals.isNotEmpty ? Colors.orange.shade800 : AppColors.themeColor)
                                        : subtitleColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      isBn
                                          ? 'আনব্লক আবেদন (${pendingAppeals.length})'
                                          : 'Appeals (${pendingAppeals.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: selectedTab == 1 ? FontWeight.w900 : FontWeight.w600,
                                        color: selectedTab == 1 ? titleColor : subtitleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedTab = 2),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedTab == 2
                                    ? (isDark ? const Color(0xFF162B27) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    size: 15,
                                    color: selectedTab == 2 ? const Color(0xFF10B981) : subtitleColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      isBn
                                          ? 'এনআইডি (${pendingVerifications.length})'
                                          : 'NID (${pendingVerifications.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: selectedTab == 2 ? FontWeight.w900 : FontWeight.w600,
                                        color: selectedTab == 2 ? titleColor : subtitleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),

                  Expanded(
                    child: selectedTab == 0
                        ? _buildPostActivityTab(
                            context: context,
                            notifications: postNotifications,
                            isBn: isBn,
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            titleColor: titleColor,
                            subtitleColor: subtitleColor,
                            adminService: adminService,
                            notifService: notifService,
                            subFilter: postActivitySubFilter,
                            onSubFilterChanged: (filter) => setModalState(() => postActivitySubFilter = filter),
                          )
                        : (selectedTab == 1
                            ? _buildReclaimAppealsTab(
                                context: context,
                                activeList: pendingAppeals,
                                isBn: isBn,
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                titleColor: titleColor,
                                subtitleColor: subtitleColor,
                                adminService: adminService,
                              )
                            : _buildNidVerificationsTab(
                                context: context,
                                activeList: pendingVerifications,
                                isBn: isBn,
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                titleColor: titleColor,
                                subtitleColor: subtitleColor,
                                adminProvider: adminProvider,
                              )),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isBn ? 'বন্ধ করুন' : 'Close', style: TextStyle(color: subtitleColor)),
                      ),
                      if (selectedTab == 0 && postNotifications.isNotEmpty)
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => notifService.markAllAdminNotificationsAsRead(),
                              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.themeColor),
                              label: Text(
                                isBn ? 'সব পড়া হয়েছে' : 'Mark all read',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                adminProvider.changeModule(AdminModule.properties);
                              },
                              child: Text(
                                isBn ? 'সকল পোস্ট দেখুন →' : 'View All Posts →',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      else if (selectedTab == 1 || selectedTab == 2)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            adminProvider.setUserManagementFilter(selectedTab == 1 ? 'Appeals' : 'Pending');
                            adminProvider.changeModule(AdminModule.users);
                          },
                          child: Text(
                            selectedTab == 1
                                ? (isBn ? 'সকল আনব্লক আবেদন দেখুন →' : 'View All Appeals →')
                                : (isBn ? 'সকল ভেরিফিকেশন আবেদন দেখুন →' : 'View All Verification →'),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildPostActivityTab({
    required BuildContext context,
    required List<AppNotificationModel> notifications,
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
    required AdminFirestoreService adminService,
    required NotificationFirestoreService notifService,
    required int subFilter,
    required void Function(int) onSubFilterChanged,
  }) {
    final languageCode = isBn ? 'bn' : 'en';
    final unreadList = notifications.where((n) => !n.isRead).toList();
    final readList = notifications.where((n) => n.isRead).toList();
    final displayedList = subFilter == 0
        ? unreadList
        : (subFilter == 1 ? readList : notifications);

    return Column(
      children: [
        // Sub-filter segmented bar: Unread | Read | All
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF081210) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // 1. Unread Sub-filter
              Expanded(
                child: InkWell(
                  onTap: () => onSubFilterChanged(0),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: subFilter == 0
                          ? (isDark ? const Color(0xFF1E3A34) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: subFilter == 0
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0284C7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isBn
                                ? 'অপঠিত (${unreadList.length.toString().toLocalizedDigits(languageCode)})'
                                : 'Unread (${unreadList.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: subFilter == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: subFilter == 0 ? titleColor : subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),

              // 2. Read Sub-filter
              Expanded(
                child: InkWell(
                  onTap: () => onSubFilterChanged(1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: subFilter == 1
                          ? (isDark ? const Color(0xFF1E3A34) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: subFilter == 1
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.done_all_rounded, size: 13, color: AppColors.themeColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isBn
                                ? 'পঠিত (${readList.length.toString().toLocalizedDigits(languageCode)})'
                                : 'Read (${readList.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: subFilter == 1 ? FontWeight.w800 : FontWeight.w600,
                              color: subFilter == 1 ? titleColor : subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),

              // 3. All Sub-filter
              Expanded(
                child: InkWell(
                  onTap: () => onSubFilterChanged(2),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: subFilter == 2
                          ? (isDark ? const Color(0xFF1E3A34) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: subFilter == 2
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 13, color: subtitleColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isBn
                                ? 'সকল (${notifications.length.toString().toLocalizedDigits(languageCode)})'
                                : 'All (${notifications.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: subFilter == 2 ? FontWeight.w800 : FontWeight.w600,
                              color: subFilter == 2 ? titleColor : subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: displayedList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            subFilter == 0
                                ? Icons.mark_email_read_rounded
                                : (subFilter == 1 ? Icons.inbox_rounded : Icons.dynamic_feed_rounded),
                            size: 38,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          subFilter == 0
                              ? (isBn ? 'বর্তমানে কোনো অপঠিত নোটিফিকেশন নেই' : 'No unread notifications')
                              : (subFilter == 1
                                  ? (isBn ? 'বর্তমানে কোনো পঠিত নোটিফিকেশন নেই' : 'No read notifications')
                                  : (isBn ? 'বর্তমানে কোনো পোস্ট নোটিফিকেশন নেই' : 'No post activities yet')),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: displayedList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notif = displayedList[index];
                    final type = notif.type;
                    Color badgeColor;
                    IconData badgeIcon;
                    String badgeLabel;

                    if (type == 'post_created') {
                      badgeColor = const Color(0xFF10B981);
                      badgeIcon = Icons.add_circle_outline_rounded;
                      badgeLabel = isBn ? 'নতুন পোস্ট' : 'New Post';
                    } else if (type == 'post_updated') {
                      badgeColor = const Color(0xFF0284C7);
                      badgeIcon = Icons.edit_note_rounded;
                      badgeLabel = isBn ? 'সংশোধিত / আপডেট' : 'Updated / Resubmitted';
                    } else if (type == 'post_deleted') {
                      badgeColor = const Color(0xFFEF4444);
                      badgeIcon = Icons.delete_outline_rounded;
                      badgeLabel = isBn ? 'মুছে ফেলা হয়েছে' : 'Deleted';
                    } else if (type == 'post_rejected') {
                      badgeColor = Colors.orange.shade800;
                      badgeIcon = Icons.cancel_outlined;
                      badgeLabel = isBn ? 'প্রত্যাখ্যাত' : 'Rejected';
                    } else {
                      badgeColor = const Color(0xFF10B981);
                      badgeIcon = Icons.check_circle_outline_rounded;
                      badgeLabel = isBn ? 'অনুমোদিত' : 'Approved';
                    }

                    final title = isBn ? (notif.titleBn.isNotEmpty ? notif.titleBn : notif.title) : notif.title;
                    final message = isBn ? (notif.messageBn.isNotEmpty ? notif.messageBn : notif.message) : notif.message;
                    final postTitle = notif.data['postTitle'] as String? ?? '';
                    final location = notif.data['location'] as String? ?? '';
                    final rawAmount = notif.data['amount'] as String? ?? (notif.data['budget'] as String? ?? '');
                    final amount = rawAmount.isNotEmpty ? (isBn ? rawAmount.toLocalizedDigits(languageCode) : rawAmount) : '';
                    final ownerName = notif.data['ownerName'] as String? ?? (notif.data['userName'] as String? ?? '');
                    final ownerEmail = notif.data['ownerEmail'] as String? ?? (notif.data['tenantEmail'] as String? ?? notif.recipientEmail);
                    final category = notif.data['category'] as String? ?? (notif.targetType == 'property' ? 'Listing' : 'Demand');

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: notif.isRead
                            ? cardBg
                            : (type == 'post_updated'
                                ? (isDark ? const Color(0xFF0B2138) : const Color(0xFFF0F9FF))
                                : (isDark ? const Color(0xFF102E24) : const Color(0xFFF0FDF4))),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: notif.isRead ? borderColor : badgeColor.withValues(alpha: 0.5),
                          width: notif.isRead ? 1 : 1.3,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(badgeIcon, size: 13, color: badgeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      badgeLabel,
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: badgeColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTimeAgo(notif.createdAt, isBn),
                                style: TextStyle(fontSize: 10, color: subtitleColor),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                color: subtitleColor,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                tooltip: isBn ? 'মুছে ফেলুন' : 'Delete',
                                onPressed: () => notifService.deleteNotification(notif.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: TextStyle(fontSize: 12, color: titleColor.withValues(alpha: 0.9), height: 1.35),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: (category == 'Listing' ? AppColors.themeColor : const Color(0xFF0284C7)).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    category == 'Listing' ? (isBn ? '🏡 বাড়িভাড়া' : '🏡 Listing') : (isBn ? '📢 চাহিদা' : '📢 Demand'),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: category == 'Listing' ? AppColors.themeColor : const Color(0xFF0284C7)),
                                  ),
                                ),
                              if (postTitle.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    postTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: titleColor),
                                  ),
                                ),
                              if (location.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    '📍 $location',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subtitleColor),
                                  ),
                                ),
                              if (amount.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.amber.shade700.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    isBn ? '$amount ৳' : '৳ $amount',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                  ),
                                ),
                              if (ownerName.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    '👤 $ownerName',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subtitleColor),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (!notif.isRead)
                                TextButton.icon(
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                                  onPressed: () => notifService.markAsRead(notif.id),
                                  icon: const Icon(Icons.check_rounded, size: 14, color: AppColors.themeColor),
                                  label: Text(isBn ? 'পড়া হয়েছে' : 'Mark Read', style: const TextStyle(fontSize: 11, color: AppColors.themeColor, fontWeight: FontWeight.bold)),
                                ),
                              if (ownerEmail.isNotEmpty || notif.recipientId.isNotEmpty)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                    minimumSize: Size.zero,
                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF0D9488)),
                                  label: Text(
                                    isBn ? 'ইউজার পোস্ট' : 'User Posts',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                  ),
                                  onPressed: () {
                                    AdminUserPostsDialog.show(
                                      context,
                                      userId: notif.recipientId,
                                      userEmail: ownerEmail,
                                      userName: ownerName,
                                      userType: category == 'Listing' ? 'House Owner' : 'Tenant',
                                      isBn: isBn,
                                      isDark: isDark,
                                    );
                                  },
                                ),
                              if (type != 'post_deleted' && notif.targetId.isNotEmpty) ...[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                    minimumSize: Size.zero,
                                    side: const BorderSide(color: Color(0xFF0284C7)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF0284C7)),
                                  label: Text(isBn ? 'ডিটেইলস' : 'Details', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                  onPressed: () => _showPostDetailsFromNotification(context, notif, isBn, isDark),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined, size: 13),
                                  label: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  onPressed: () => _showAdminRejectPostDialog(context, notif, isBn, adminService, notifService),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 13),
                                  label: Text(isBn ? 'অনুমোদন' : 'Approve', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    if (notif.targetType == 'property') {
                                      await adminService.updatePropertyApproval(notif.targetId, 'approved');
                                    } else {
                                      await adminService.updateDemandApproval(notif.targetId, 'approved');
                                    }
                                    await notifService.markAsRead(notif.id);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static Widget _buildReclaimAppealsTab({
    required BuildContext context,
    required List<UserModel> activeList,
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
    required AdminFirestoreService adminService,
  }) {
    if (activeList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(Icons.mark_email_read_rounded, size: 38, color: subtitleColor),
              ),
              const SizedBox(height: 14),
              Text(
                isBn ? 'বর্তমানে কোনো পেন্ডিং আনব্লক আবেদন নেই' : 'No pending reclaim appeals',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subtitleColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: activeList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = activeList[index];
        final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: Text(user.initials, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isNotEmpty ? name : 'User', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: titleColor)),
                        Text(user.mobile.isNotEmpty ? user.mobile : user.email, style: TextStyle(fontSize: 11, color: subtitleColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      icon: const Icon(Icons.check_circle_rounded, size: 14),
                      label: Text(isBn ? 'অনুমোদন' : 'Approve', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      onPressed: () async {
                        Navigator.pop(context);
                        await adminService.resolveUserAppeal(user.uid, approve: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      icon: const Icon(Icons.cancel_outlined, size: 14),
                      label: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      onPressed: () => _showAdminRejectAppealDialog(context, user, isBn, adminService),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showAdminRejectPostDialog(
    BuildContext context,
    AppNotificationModel notif,
    bool isBn,
    AdminFirestoreService adminService,
    NotificationFirestoreService notifService,
  ) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'পোস্ট প্রত্যাখ্যানের কারণ' : 'Post Rejection Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBn
                  ? 'ব্যবহারকারীর কাছে এই কারণটি নোটিফিকেশন আকারে যাবে যেন তারা সংশোধন করতে পারে:'
                  : 'This reason will be sent to the user so they can correct and resubmit:',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isBn ? 'সঠিক কারণ বিস্তারিত লিখুন...' : 'Enter rejection reason...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              Navigator.pop(c);
              if (notif.targetType == 'property') {
                await adminService.updatePropertyApproval(notif.targetId, 'rejected', reason: reason);
              } else {
                await adminService.updateDemandApproval(notif.targetId, 'rejected', reason: reason);
              }
              await notifService.markAsRead(notif.id);
            },
            child: Text(isBn ? 'প্রত্যাখ্যান নিশ্চিত করুন' : 'Confirm Reject'),
          ),
        ],
      ),
    );
  }

  static void _showAdminRejectAppealDialog(BuildContext context, UserModel user, bool isBn, AdminFirestoreService adminService) {
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'আবেদন প্রত্যাখ্যান' : 'Reject Appeal'),
        content: TextField(
          controller: feedbackCtrl,
          decoration: InputDecoration(hintText: isBn ? 'কারণ লিখুন...' : 'Enter reason...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(c);
              await adminService.resolveUserAppeal(user.uid, approve: false, adminFeedback: feedbackCtrl.text);
            },
            child: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject'),
          ),
        ],
      ),
    );
  }

  static Widget _buildNidVerificationsTab({
    required BuildContext context,
    required List<UserModel> activeList,
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
    required AdminProvider adminProvider,
  }) {
    if (activeList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(Icons.verified_user_rounded, size: 38, color: subtitleColor),
              ),
              const SizedBox(height: 14),
              Text(
                isBn ? 'কোনো ভেরিফিকেশন আবেদন নেই' : 'No pending requests',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subtitleColor),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: activeList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = activeList[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
          child: Row(
            children: [
              Expanded(
                child: Text(user.fullName, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  adminProvider.setUserManagementFilter('Pending');
                  adminProvider.changeModule(AdminModule.users);
                },
                child: Text(isBn ? 'রিভিউ' : 'Review'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _showPostDetailsFromNotification(BuildContext context, AppNotificationModel notif, bool isBn, bool isDark) async {
    try {
      if (notif.targetType == 'property') {
        final doc = await FirebaseFirestore.instance.collection('properties').doc(notif.targetId).get();
        if (doc.exists && doc.data() != null && context.mounted) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          final property = PropertyModel.fromMap(data, doc.id);
          AdminPostDetailsDialog.showPropertyDetails(
            context,
            property,
            isBn: isBn,
            isDark: isDark,
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBn ? 'বিজ্ঞাপনটি খুঁজে পাওয়া যায়নি বা মুছে ফেলা হয়েছে।' : 'Property not found or deleted.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        final doc = await FirebaseFirestore.instance.collection('tenant_demands').doc(notif.targetId).get();
        if (doc.exists && doc.data() != null && context.mounted) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          final demand = TenantDemandModel.fromMap(data, doc.id);
          AdminPostDetailsDialog.showDemandDetails(
            context,
            demand,
            isBn: isBn,
            isDark: isDark,
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBn ? 'চাহিদা পোস্টটি খুঁজে পাওয়া যায়নি বা মুছে ফেলা হয়েছে।' : 'Demand post not found or deleted.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening post details screen from notification: $e');
    }
  }

  static String _formatTimeAgo(DateTime dt, bool isBn) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isBn ? 'এখনই' : 'just now';
    if (diff.inMinutes < 60) return isBn ? '${diff.inMinutes} মিনিট আগে' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isBn ? '${diff.inHours} ঘণ্টা আগে' : '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
