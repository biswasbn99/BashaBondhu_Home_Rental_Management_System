import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/theme_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../shared/presentation/widgets/full_screen_image_viewer.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';
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

                            // Notification Bell Icon with Pending Verification Requests Badge
                            StreamBuilder<List<UserModel>>(
                              stream: AdminFirestoreService().streamAllUsers(),
                              builder: (context, snapshot) {
                                final allUsers = snapshot.data ?? [];
                                final pendingUsers = allUsers.where((u) => u.isVerificationPending).toList();
                                final count = pendingUsers.length;

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
                                        color: count > 0 ? Colors.amber.shade700 : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                        size: 20,
                                      ),
                                      tooltip: isBn ? 'ভেরিফিকেশন আবেদন নোটিফিকেশন ($count)' : 'Verification Requests ($count)',
                                      onPressed: () => _showVerificationRequestsModal(context, pendingUsers, isBn, isDark, adminProvider),
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
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

  void _showVerificationRequestsModal(
    BuildContext context,
    List<UserModel> pendingUsers,
    bool isBn,
    bool isDark,
    AdminProvider adminProvider,
  ) {
    final modalBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final cardBg = isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: modalBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.mark_email_unread_rounded, color: Colors.amber.shade700, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isBn
                            ? 'ভেরিফিকেশন আবেদনসমূহ (${pendingUsers.length})'
                            : 'Verification Requests (${pendingUsers.length})',
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
              const SizedBox(height: 12),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 14),

              // Content List or Empty State
              Expanded(
                child: pendingUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white10 : Colors.grey.shade100),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.verified_user_rounded, size: 40, color: subtitleColor),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isBn
                                    ? 'বর্তমানে কোনো নতুন ভেরিফিকেশন আবেদন নেই'
                                    : 'No pending verification requests at this moment',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isBn
                                    ? 'ইউজাররা তাদের প্রোফাইল ও এনআইডি জমা দিলে এখানে নোটিফিকেশন আসবে।'
                                    : 'When users complete profile and submit NID, requests will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtitleColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: pendingUsers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = pendingUsers[index];
                          final name = user.fullName.isNotEmpty
                              ? user.fullName
                              : "${user.firstName} ${user.lastName}".trim();

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor, width: 1.1),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                InkWell(
                                  onTap: user.profileImageUrl.isNotEmpty
                                      ? () => FullScreenImageViewer.show(
                                            context,
                                            images: [user.profileImageUrl],
                                            title: isBn ? '$name - প্রোফাইল ছবি' : '$name - Profile Picture',
                                          )
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.themeColor.withValues(alpha: 0.2),
                                    child: user.profileImageUrl.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              user.profileImageUrl,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 20),
                                            ),
                                          )
                                        : Text(
                                            user.initials,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.themeColor,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // User Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name.isNotEmpty ? name : 'User',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: titleColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (user.userType == 'House Owner'
                                                      ? AppColors.themeColor
                                                      : const Color(0xFF0284C7))
                                                  .withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              user.userType,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: user.userType == 'House Owner'
                                                    ? AppColors.themeColor
                                                    : const Color(0xFF0284C7),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${user.mobile.isNotEmpty ? user.mobile : user.email} • ${user.city.isNotEmpty ? user.city : "Location N/A"}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11.5, color: subtitleColor, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Action Button
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.themeColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  icon: const Icon(Icons.rate_review_rounded, size: 14),
                                  label: Text(isBn ? 'রিভিউ করুন' : 'Review'),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    adminProvider.setUserManagementFilter('Pending');
                                    adminProvider.changeModule(AdminModule.users);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 12),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(isBn ? 'বন্ধ করুন' : 'Close', style: TextStyle(color: subtitleColor)),
                  ),
                  if (pendingUsers.isNotEmpty)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        adminProvider.setUserManagementFilter('Pending');
                        adminProvider.changeModule(AdminModule.users);
                      },
                      child: Text(
                        isBn ? 'সকল আবেদন দেখুন →' : 'View All Pending →',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
