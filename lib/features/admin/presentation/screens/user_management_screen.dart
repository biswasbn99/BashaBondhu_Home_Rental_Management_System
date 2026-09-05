import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../shared/presentation/widgets/full_screen_image_viewer.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../subscription/data/services/subscription_firestore_service.dart';
import '../widgets/admin_user_posts_dialog.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;
    _selectedFilter = adminProvider.userManagementFilter;

    return StreamBuilder<List<UserModel>>(
      stream: _adminService.streamAllUsers(),
      builder: (context, snapshot) {
        final allUsers = snapshot.data ?? [];

        // Apply Search & Filter
        final filteredUsers = allUsers.where((u) {
          final query = _searchQuery.toLowerCase();
          final name = u.fullName.toLowerCase();
          final email = u.email.toLowerCase();
          final phone = u.mobile.toLowerCase();
          final uid = u.uid.toLowerCase();

          final matchesSearch = query.isEmpty ||
              name.contains(query) ||
              email.contains(query) ||
              phone.contains(query) ||
              uid.contains(query);

          if (!matchesSearch) return false;

          switch (_selectedFilter) {
            case 'Owners':
              return u.userType == 'House Owner';
            case 'Tenants':
              return u.userType == 'Tenant';
            case 'Verified':
              return u.isVerified;
            case 'Pending':
              return u.isVerificationPending;
            case 'Appeals':
              return u.appealStatus == 'pending';
            case 'Blocked':
              return u.isBlocked;
            case 'Unverified':
              return !u.isVerified && !u.isVerificationPending;
            default:
              return true;
          }
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                isBn ? 'ইউজার ম্যানেজমেন্ট ও এনআইডি ভেরিফিকেশন' : 'User Management & NID Verification',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.themeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBn
                    ? 'বাড়িওয়ালা, ভাড়াটিয়া ও রিয়েল-টাইম প্রোফাইল ভেরিফিকেশন নিয়ন্ত্রণ করুন (${filteredUsers.length} জন ইউজার)'
                    : 'Manage House Owners, Tenants, and live user verification statuses (${filteredUsers.length} users)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 20),

              // Search and Filter Bar with Responsive LayoutBuilder
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F201D) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 550) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: isBn
                                    ? 'নাম, ইমেইল, মোবাইল দিয়ে খুঁজুন...'
                                    : 'Search by Name, Email, Phone...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _buildFilterDropdown(isBn, isDark),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: isBn
                                  ? 'নাম, ইমেইল, মোবাইল দিয়ে খুঁজুন...'
                                  : 'Search by Name, Email, Phone...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: _buildFilterDropdown(isBn, isDark),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Users DataTable
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F201D) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: filteredUsers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.person_off_rounded, size: 44, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(
                                isBn ? 'কোনো ইউজার পাওয়া যায়নি' : 'No users found matching query',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          columns: [
                            DataColumn(label: Text(isBn ? 'ইউজার' : 'User', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'রোল' : 'Role', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'সাবস্ক্রিপশন' : 'Subscription', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'পোস্টসমূহ' : 'Posts', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'যোগাযোগ' : 'Contact', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'ভেরিফিকেশন স্ট্যাটাস' : 'Verification Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'প্রোফাইল' : 'Profile %', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'অ্যাকশন' : 'Actions', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredUsers.map((user) {
                            final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: user.profileImageUrl.isNotEmpty
                                            ? () => FullScreenImageViewer.show(
                                                  context,
                                                  images: [user.profileImageUrl],
                                                  title: isBn ? '$name - প্রোফাইল ছবি' : '$name - Profile Picture',
                                                )
                                            : null,
                                        borderRadius: BorderRadius.circular(18),
                                        child: CircleAvatar(
                                          radius: 17,
                                          backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
                                          child: user.profileImageUrl.isNotEmpty
                                              ? ClipOval(child: _buildImage(user.profileImageUrl, 34, 34))
                                              : Text(user.initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.themeColor)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              name.isNotEmpty ? name : 'User',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                            ),
                                            Text(
                                              user.email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (user.userType == 'House Owner' ? AppColors.themeColor : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.userType,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: user.userType == 'House Owner' ? AppColors.themeColor : const Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _buildSubscriptionBadge(user, isBn, isDark),
                                ),
                                DataCell(
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.themeColor,
                                      side: BorderSide(color: AppColors.themeColor.withValues(alpha: 0.4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.dynamic_feed_rounded, size: 13),
                                    label: Text(
                                      isBn ? 'পোস্ট দেখুন' : 'Posts',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => AdminUserPostsDialog.show(
                                      context,
                                      userId: user.uid,
                                      userEmail: user.email,
                                      userName: name,
                                      userType: user.userType,
                                      isBn: isBn,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                                DataCell(Text(user.mobile.isNotEmpty ? user.mobile : 'N/A', style: const TextStyle(fontSize: 11.5))),
                                DataCell(
                                  _buildVerificationBadge(user, isBn, isDark),
                                ),
                                DataCell(
                                  Text(
                                    '${user.profileCompletionPercentage}%',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: user.profileCompletionPercentage == 100 ? const Color(0xFF10B981) : Colors.orange,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                                        tooltip: isBn ? 'ইউজার বিবরণ দেখুন' : 'View User Details',
                                        onPressed: () => _showUserDetailsModal(context, user, isBn, isDark),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.dynamic_feed_rounded, size: 18, color: Colors.purple),
                                        tooltip: isBn ? 'ইউজারের সকল পোস্ট' : "View User's All Posts",
                                        onPressed: () => AdminUserPostsDialog.show(
                                          context,
                                          userId: user.uid,
                                          userEmail: user.email,
                                          userName: name,
                                          userType: user.userType,
                                          isBn: isBn,
                                          isDark: isDark,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          user.isVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                                          size: 18,
                                          color: user.isVerified ? const Color(0xFF10B981) : Colors.amber.shade700,
                                        ),
                                        tooltip: isBn ? 'ভেরিফিকেশন পরিচালনা করুন' : 'Manage Verification',
                                        onPressed: () => _showVerifyNidDialog(context, user, isBn, isDark),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          user.isBlocked ? Icons.lock_open_rounded : Icons.block_flipped,
                                          size: 18,
                                          color: user.isBlocked ? const Color(0xFF10B981) : Colors.orange,
                                        ),
                                        tooltip: user.isBlocked ? (isBn ? 'আনব্লক করুন' : 'Unblock User') : (isBn ? 'ব্লক / সাসপেন্ড' : 'Block / Suspend'),
                                        onPressed: () => _showBlockDialog(context, user, isBn, isDark),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        tooltip: isBn ? 'মুছে ফেলুন' : 'Delete User',
                                        onPressed: () => _showDeleteDialog(context, user, isBn),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationBadge(UserModel user, bool isBn, bool isDark) {
    if (user.isBlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block_rounded, size: 12, color: Colors.redAccent),
            const SizedBox(width: 4),
            Text(
              isBn ? 'সাসপেন্ডেড' : 'Suspended',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.redAccent),
            ),
          ],
        ),
      );
    } else if (user.appealStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 12, color: isDark ? Colors.amberAccent : Colors.amber.shade800),
            const SizedBox(width: 4),
            Text(
              isBn ? 'আপিল পেন্ডিং' : 'Appeal Pending',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isDark ? Colors.amberAccent : Colors.amber.shade900),
            ),
          ],
        ),
      );
    } else if (user.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              isBn ? 'ভেরিফাইড' : 'Verified',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
            ),
          ],
        ),
      );
    } else if (user.isVerificationPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 12, color: isDark ? Colors.amberAccent : Colors.amber.shade800),
            const SizedBox(width: 4),
            Text(
              isBn ? 'পেন্ডিং' : 'Pending',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isDark ? Colors.amberAccent : Colors.amber.shade900),
            ),
          ],
        ),
      );
    } else if (user.isVerificationRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded, size: 12, color: Colors.redAccent),
            const SizedBox(width: 4),
            Text(
              isBn ? 'সংশোধন প্রয়োজন' : 'Action Needed',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.redAccent),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isBn ? 'অ-ভেরিফাইড' : 'Unverified',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
      );
    }
  }

  Widget _buildFilterDropdown(bool isBn, bool isDark) {
    final adminProvider = context.read<AdminProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF223E38) : const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          items: [
            DropdownMenuItem(value: 'All', child: Text(isBn ? '👥 সকল ইউজার (All)' : '👥 All Users')),
            DropdownMenuItem(value: 'Pending', child: Text(isBn ? '📩 ভেরিফিকেশন আবেদন (Requests)' : '📩 Verification Requests')),
            DropdownMenuItem(value: 'Appeals', child: Text(isBn ? '⚖️ আনব্লক আবেদন (Reclaim Appeals)' : '⚖️ Reclaim Appeals')),
            DropdownMenuItem(value: 'Blocked', child: Text(isBn ? '🚫 সাসপেন্ডেড ইউজার (Blocked)' : '🚫 Blocked Users')),
            DropdownMenuItem(value: 'Owners', child: Text(isBn ? '🏡 বাড়িওয়ালা (Owners)' : '🏡 House Owners')),
            DropdownMenuItem(value: 'Tenants', child: Text(isBn ? '👤 ভাড়াটিয়া (Tenants)' : '👤 Tenants')),
            DropdownMenuItem(value: 'Verified', child: Text(isBn ? '✅ ভেরিফাইড (Verified)' : '✅ Verified')),
            DropdownMenuItem(value: 'Unverified', child: Text(isBn ? '⚪ অ-ভেরিফাইড (Unverified)' : '⚪ Unverified')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedFilter = val);
              adminProvider.setUserManagementFilter(val);
            }
          },
        ),
      ),
    );
  }

  // --- 1. User Details Modal Card (High-Contrast Light & Dark Mode) ---
  void _showUserDetailsModal(BuildContext context, UserModel user, bool isBn, bool isDark) {
    final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
    final modalBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final headerBg = isDark ? const Color(0xFF142C27) : const Color(0xFFF1F8F6);
    final cardBg = isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);

    // Color definitions for light and dark modes
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155);
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: modalBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: borderColor, width: 1.2)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
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
                          child: const Icon(Icons.badge_rounded, color: AppColors.themeColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isBn ? 'ইউজার প্রোফাইল ও ভেরিফিকেশন বিবরণ' : 'User Profile & Verification Details',
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
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 16),

                // User Profile Header Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: headerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.themeColor.withValues(alpha: isDark ? 0.3 : 0.2)),
                  ),
                  child: Row(
                    children: [
                      // Clickable Profile Image for Zoom
                      InkWell(
                        onTap: user.profileImageUrl.isNotEmpty
                            ? () => FullScreenImageViewer.show(
                                  context,
                                  images: [user.profileImageUrl],
                                  title: isBn ? '$name - প্রোফাইল ছবি' : '$name - Profile Picture',
                                )
                            : null,
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.themeColor.withValues(alpha: 0.2),
                              child: user.profileImageUrl.isNotEmpty
                                  ? ClipOval(child: _buildImage(user.profileImageUrl, 64, 64))
                                  : Text(user.initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.themeColor)),
                            ),
                            if (user.profileImageUrl.isNotEmpty)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.themeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildVerificationBadge(user, isBn, isDark),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${user.userType} • ${user.mobile.isNotEmpty ? user.mobile : "No Phone Registered"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.themeColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Suspension Alert Box (if blocked)
                if (user.isBlocked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.block_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isBn ? 'একাউন্ট সাসপেন্ডেড (Account Suspended)' : 'Account Suspended',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.redAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${isBn ? "কারণ" : "Reason"}: ${user.blockReason.isNotEmpty ? user.blockReason : (isBn ? "নীতিমালা লঙ্ঘন" : "Policy violation")}',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: titleColor),
                        ),
                        if (user.blockedAt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${isBn ? "সাসপেন্ডের তারিখ" : "Suspended At"}: ${user.blockedAt}',
                            style: TextStyle(fontSize: 11, color: subtitleColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Pending Reclaim Appeal Box (if appeal pending)
                if (user.appealStatus == 'pending') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.mark_email_unread_rounded, color: isDark ? Colors.amberAccent : Colors.amber.shade900, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isBn ? 'আনব্লক / রিক্লেইম আবেদন (Appeal Pending)' : 'Reclaim Appeal Pending Review',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                  color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${isBn ? "ইউজারের ব্যাখ্যা" : "User's Explanation"}:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: subtitleColor),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            user.appealNote.isNotEmpty ? user.appealNote : 'No note provided',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: titleColor),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${isBn ? "যোগাযোগ" : "Contact"}: ${user.appealContact.isNotEmpty ? user.appealContact : user.mobile} • ${user.appealAt}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtitleColor),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.check_circle_rounded, size: 15),
                                label: Text(
                                  isBn ? 'অনুমোদন ও আনব্লক' : 'Approve & Unblock',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _adminService.resolveUserAppeal(user.uid, approve: true);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isBn ? 'আবেদন অনুমোদিত ও ইউজার আনব্লক হয়েছে!' : 'Appeal approved & user unblocked!'),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.cancel_outlined, size: 15),
                                label: Text(
                                  isBn ? 'আবেদন বাতিল' : 'Reject Appeal',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showRejectAppealDialog(context, user, isBn, isDark);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Info Grid Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('UID', user.uid, labelColor, valueColor),
                      _buildInfoRow(isBn ? 'লিঙ্গ' : 'Gender', user.gender.isNotEmpty ? user.gender : 'N/A', labelColor, valueColor),
                      _buildInfoRow(isBn ? 'জন্ম তারিখ' : 'Date of Birth', user.dateOfBirth.isNotEmpty ? user.dateOfBirth : 'N/A', labelColor, valueColor),
                      _buildInfoRow(isBn ? 'শহর / অবস্থান' : 'City / Location', user.city.isNotEmpty ? user.city : 'N/A', labelColor, valueColor),
                      _buildInfoRow(isBn ? 'প্রোফাইল সম্পূর্ণতা' : 'Profile Completion', '${user.profileCompletionPercentage}%', labelColor, valueColor),
                      _buildInfoRow(isBn ? 'নিবন্ধনের তারিখ' : 'Registration Date', user.createdAt, labelColor, valueColor),
                      if (user.verificationFeedback.isNotEmpty) ...[
                        const Divider(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'অ্যাডমিন রিমার্ক / ফিডব্যাক:' : 'Admin Feedback:',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.verificationFeedback,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: titleColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // NID Documents Section with Zoom Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBn ? 'জাতীয় পরিচয়পত্র (NID Images):' : 'National ID (NID Images):',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: titleColor),
                    ),
                    Text(
                      isBn ? '🔎 ছবিতে ক্লিক করে জুম করুন' : '🔎 Click image to Zoom In/Out',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.themeColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // Front NID Image
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isBn ? 'সামনের দিক (Front Side):' : 'Front Side:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: subtitleColor)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: user.nidFrontImageUrl.isNotEmpty
                                ? () => FullScreenImageViewer.show(
                                      context,
                                      images: [
                                        user.nidFrontImageUrl,
                                        if (user.nidBackImageUrl.isNotEmpty) user.nidBackImageUrl,
                                      ],
                                      initialIndex: 0,
                                      title: isBn ? '$name - জাতীয় পরিচয়পত্র (সামনে)' : '$name - NID Front Side',
                                    )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 125,
                              decoration: BoxDecoration(
                                color: cardBg,
                                border: Border.all(color: borderColor, width: 1.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: user.nidFrontImageUrl.isNotEmpty
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(borderRadius: BorderRadius.circular(11), child: _buildImage(user.nidFrontImageUrl, double.infinity, 125)),
                                        Positioned(
                                          bottom: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.65),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                                                const SizedBox(width: 3),
                                                Text(isBn ? 'জুম' : 'Zoom', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.credit_card_off_rounded, size: 28, color: subtitleColor),
                                          const SizedBox(height: 4),
                                          Text(isBn ? 'ছবি নেই' : 'No Image', style: TextStyle(color: subtitleColor, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Back NID Image
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isBn ? 'পেছনের দিক (Back Side):' : 'Back Side:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: subtitleColor)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: user.nidBackImageUrl.isNotEmpty
                                ? () => FullScreenImageViewer.show(
                                      context,
                                      images: [
                                        if (user.nidFrontImageUrl.isNotEmpty) user.nidFrontImageUrl,
                                        user.nidBackImageUrl,
                                      ],
                                      initialIndex: user.nidFrontImageUrl.isNotEmpty ? 1 : 0,
                                      title: isBn ? '$name - জাতীয় পরিচয়পত্র (পেছনে)' : '$name - NID Back Side',
                                    )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 125,
                              decoration: BoxDecoration(
                                color: cardBg,
                                border: Border.all(color: borderColor, width: 1.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: user.nidBackImageUrl.isNotEmpty
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(borderRadius: BorderRadius.circular(11), child: _buildImage(user.nidBackImageUrl, double.infinity, 125)),
                                        Positioned(
                                          bottom: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.65),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                                                const SizedBox(width: 3),
                                                Text(isBn ? 'জুম' : 'Zoom', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.flip_to_back_rounded, size: 28, color: subtitleColor),
                                          const SizedBox(height: 4),
                                          Text(isBn ? 'ছবি নেই' : 'No Image', style: TextStyle(color: subtitleColor, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User Posts Direct Action Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dynamic_feed_rounded, color: AppColors.themeColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isBn ? 'ইউজারের সকল বিজ্ঞাপন ও চাহিদা পোস্ট' : 'User Listings & Demands',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
                          foregroundColor: AppColors.themeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: Text(isBn ? 'পোস্টসমূহ দেখুন' : 'View Posts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          AdminUserPostsDialog.show(
                            context,
                            userId: user.uid,
                            userEmail: user.email,
                            userName: name,
                            userType: user.userType,
                            isBn: isBn,
                            isDark: isDark,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Subscription Status Card
                _buildUserSubscriptionDetailsSection(user, isBn, isDark, cardBg, borderColor, titleColor, subtitleColor),
                const SizedBox(height: 16),

                // Subscription Transaction History
                _buildSubscriptionHistorySection(user, isBn, isDark, cardBg, borderColor, titleColor, subtitleColor),
                const SizedBox(height: 20),

                // Action Buttons at Bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: Text(isBn ? 'বন্ধ করুন' : 'Close', style: TextStyle(color: titleColor, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: user.isBlocked ? const Color(0xFF10B981) : Colors.orange,
                        side: BorderSide(color: user.isBlocked ? const Color(0xFF10B981) : Colors.orange),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: Icon(user.isBlocked ? Icons.lock_open_rounded : Icons.block_flipped, size: 16),
                      label: Text(
                        user.isBlocked ? (isBn ? 'আনব্লক' : 'Unblock') : (isBn ? 'ব্লক' : 'Block'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showBlockDialog(context, user, isBn, isDark);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: user.isVerified ? Colors.amber.shade800 : const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: Icon(user.isVerified ? Icons.edit_note_rounded : Icons.verified_rounded, size: 16),
                      label: Text(
                        user.isVerified ? (isBn ? 'স্ট্যাটাস পরিবর্তন' : 'Change Status') : (isBn ? 'ভেরিফাই করুন' : 'Verify NID'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showVerifyNidDialog(context, user, isBn, isDark);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge(UserModel user, bool isBn, bool isDark) {
    if (user.subscriptionPlanId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              isBn ? 'ফ্রি' : 'Free',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    final expiryStr = user.subscriptionExpiryDate;
    if (expiryStr.isNotEmpty) {
      final expiryDate = DateTime.tryParse(expiryStr);
      if (expiryDate != null) {
        final remainingDays = expiryDate.difference(DateTime.now()).inDays;
        if (remainingDays >= 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  isBn ? 'প্যাকেজ (${remainingDays + 1} দিন)' : 'Plan (${remainingDays + 1}d)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  isBn ? 'মেয়াদোত্তীর্ণ' : 'Expired',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        user.subscriptionPlanId,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
      ),
    );
  }

  Widget _buildUserSubscriptionDetailsSection(
    UserModel user,
    bool isBn,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    final hasPlan = user.subscriptionPlanId.isNotEmpty;
    DateTime? expiryDate;
    int remainingDays = 0;
    bool isExpired = false;

    if (user.subscriptionExpiryDate.isNotEmpty) {
      expiryDate = DateTime.tryParse(user.subscriptionExpiryDate);
      if (expiryDate != null) {
        remainingDays = expiryDate.difference(DateTime.now()).inDays;
        isExpired = remainingDays < 0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: AppColors.themeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? 'সাবস্ক্রিপশন স্ট্যাটাস (Subscription Status)' : 'Subscription Status',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: titleColor),
                  ),
                ],
              ),
              if (hasPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isExpired ? Colors.redAccent : const Color(0xFF10B981)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: (isExpired ? Colors.redAccent : const Color(0xFF10B981)).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    isExpired
                        ? (isBn ? '⚠️ মেয়াদোত্তীর্ণ (Expired)' : '⚠️ Expired')
                        : (isBn ? '⏳ আর ${remainingDays + 1} দিন বাকি' : '⏳ ${remainingDays + 1} days left'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isExpired ? Colors.redAccent : const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            isBn ? 'প্ল্যান / প্যাকেজ' : 'Plan Name',
            hasPlan ? user.subscriptionPlanId : (isBn ? 'ফ্রি একাউন্ট (Free Account)' : 'Free Account'),
            subtitleColor,
            titleColor,
          ),
          if (expiryDate != null) ...[
            _buildInfoRow(
              isBn ? 'মেয়াদ শেষের তারিখ' : 'Expiry Date',
              '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
              subtitleColor,
              titleColor,
            ),
          ],
          if (user.unlockedPropertyIds.isNotEmpty)
            _buildInfoRow(
              isBn ? 'আনলকড বিজ্ঞাপন' : 'Unlocked Properties',
              '${user.unlockedPropertyIds.length} টি',
              subtitleColor,
              titleColor,
            ),
          if (user.unlockedDemandIds.isNotEmpty)
            _buildInfoRow(
              isBn ? 'আনলকড চাহিদা' : 'Unlocked Demands',
              '${user.unlockedDemandIds.length} টি',
              subtitleColor,
              titleColor,
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistorySection(
    UserModel user,
    bool isBn,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              Text(
                isBn ? 'সাবস্ক্রিপশন লেনদেন বিবরণী (Transaction History)' : 'Subscription History',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<SubscriptionTransactionModel>>(
            stream: SubscriptionFirestoreService().streamUserTransactions(user.uid),
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? [];

              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      isBn ? 'কোনো পূর্ববর্তী সাবস্ক্রিপশন লেনদেন পাওয়া যায়নি' : 'No subscription transaction records found',
                      style: TextStyle(fontSize: 12, color: subtitleColor, fontStyle: FontStyle.italic),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 8,
                  headingRowHeight: 36,
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 44,
                  columns: [
                    DataColumn(label: Text(isBn ? 'প্ল্যান' : 'Plan', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isBn ? 'টাকা' : 'Amount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isBn ? 'মাধ্যম / TrxID' : 'Method / TrxID', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isBn ? 'তারিখ' : 'Date', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isBn ? 'স্ট্যাটাস' : 'Status', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                  rows: transactions.map((trx) {
                    final isTrxActive = trx.expiresAt.isAfter(DateTime.now());
                    return DataRow(
                      cells: [
                        DataCell(Text(trx.planTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataCell(Text('${trx.amountPaid.toInt()} ৳', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.themeColor))),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(trx.paymentMethod, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                              Text(trx.transactionId, style: TextStyle(fontSize: 9.5, color: subtitleColor)),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '${trx.purchasedAt.day}/${trx.purchasedAt.month}/${trx.purchasedAt.year}',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isTrxActive ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTrxActive ? (isBn ? 'সক্রিয়' : 'Active') : (isBn ? 'মেয়াদোত্তীর্ণ' : 'Expired'),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isTrxActive ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(color: labelColor, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Advanced Confirmation & Verification Action Dialog ---
  void _showVerifyNidDialog(BuildContext context, UserModel user, bool isBn, bool isDark) {
    final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
    final feedbackController = TextEditingController(text: user.verificationFeedback);
    bool showFeedbackField = user.isVerificationRejected;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dialogBg = isDark ? const Color(0xFF0F201D) : Colors.white;
          final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
          final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
          final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: borderColor, width: 1.2)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBn ? 'ইউজার ভেরিফিকেশন ম্যানেজমেন্ট' : 'User Verification Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: titleColor),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBn
                        ? 'ইউজার: $name (${user.userType})\nবর্তমান স্ট্যাটাস: ${user.isVerified ? "ভেরিফাইড" : (user.isVerificationPending ? "পেন্ডিং" : "অ-ভেরিফাইড")}'
                        : 'User: $name (${user.userType})\nCurrent Status: ${user.isVerified ? "Verified" : (user.isVerificationPending ? "Pending" : "Unverified")}',
                    style: TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBn ? 'ভেরিফিকেশন অ্যাকশন সিলেক্ট করুন:' : 'Select Verification Action:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: subtitleColor),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: Approve / Verify
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isBn ? 'অনুমোদন ও ভেরিফাই করুন (Verify)' : 'Approve & Verify User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _confirmAction(
                        context: context,
                        isBn: isBn,
                        title: isBn ? 'ভেরিফিকেশন অনুমোদন নিশ্চিত করুন' : 'Confirm Verification Approval',
                        message: isBn
                            ? 'আপনি কি $name এর প্রোফাইল ভেরিফাই করতে চান? এটি ইউজারের প্রোফাইল ও বিজ্ঞাপনে ভেরিফাইড ব্যাজ প্রদর্শন করবে।'
                            : 'Are you sure you want to verify $name? This will display a verified badge on their profile and posts.',
                        confirmText: isBn ? 'ভেরিফাই করুন' : 'Confirm Verify',
                        confirmColor: const Color(0xFF10B981),
                        onConfirm: () async {
                          await _adminService.updateUserNidStatus(user.uid, 'verified');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isBn ? 'ইউজার সফলভাবে ভেরিফাই করা হয়েছে!' : 'User verified successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Unverify
                  if (user.isVerified) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber.shade800,
                        side: BorderSide(color: Colors.amber.shade800, width: 1.4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.remove_moderator_rounded, size: 18),
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isBn ? 'আনভেরিফাই করুন (Unverify)' : 'Unverify User', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        ],
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _confirmAction(
                          context: context,
                          isBn: isBn,
                          title: isBn ? 'আনভেরিফাই নিশ্চিত করুন' : 'Confirm Unverify',
                          message: isBn
                              ? 'আপনি কি $name এর ভেরিফিকেশন বাতিল করতে চান? ইউজারের প্রোফাইল আবার অ-ভেরিফাইড হয়ে যাবে।'
                              : 'Are you sure you want to revoke verification for $name? Their profile status will become unverified.',
                          confirmText: isBn ? 'আনভেরিফাই' : 'Unverify',
                          confirmColor: Colors.amber.shade900,
                          onConfirm: () async {
                            await _adminService.updateUserNidStatus(user.uid, 'unverified');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isBn ? 'ইউজারকে আনভেরিফাইড করা হয়েছে।' : 'User status updated to unverified.'),
                                  backgroundColor: Colors.amber.shade900,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Option 3: Request Correction / Reject with Feedback
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.feedback_rounded, size: 18),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isBn ? 'ভুল তথ্য / সংশোধনের নির্দেশ দিন' : 'Request Correction / Send Feedback', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Icon(showFeedbackField ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16),
                      ],
                    ),
                    onPressed: () {
                      setDialogState(() {
                        showFeedbackField = !showFeedbackField;
                      });
                    },
                  ),

                  // Expandable Feedback Input Field
                  if (showFeedbackField) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isBn
                            ? 'সংশোধনের নির্দিষ্ট কারণ লিখুন (যেমন: NID ছবি অস্পষ্ট, সঠিক ছবি আপলোড করুন)...'
                            : 'Enter specific reason for correction (e.g. NID image is blurry)...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(isBn ? 'ইউজারকে ফিডব্যাক পাঠান ও রিজেক্ট করুন' : 'Send Feedback & Mark Action Needed'),
                      onPressed: () async {
                        final reason = feedbackController.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isBn ? 'অনুগ্রহ করে কারণ লিখুন।' : 'Please enter feedback reason.')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        await _adminService.updateUserNidStatus(user.uid, 'rejected', reason: reason);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isBn ? 'সংশোধনের নির্দেশ সফলভাবে পাঠানো হয়েছে!' : 'Correction feedback sent successfully!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isBn ? 'বন্ধ করুন' : 'Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmAction({
    required BuildContext context,
    required bool isBn,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, UserModel user, bool isBn, bool isDark) {
    final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();

    // If user is already blocked, show Unblock confirmation dialog
    if (user.isBlocked) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F201D) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.lock_open_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn ? 'ইউজার আনব্লক করুন' : 'Unblock User Account',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            isBn
                ? 'আপনি কি $name এর একাউন্টটি আনব্লক ও পুনরায় সচল করতে চান? ইউজার সাথে সাথে অ্যাপের সকল সুবিধা ব্যবহার করতে পারবেন।'
                : 'Are you sure you want to unblock and reinstate $name? The user will immediately regain full access.',
            style: const TextStyle(fontSize: 13.5, height: 1.45),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                Navigator.pop(ctx);
                await _adminService.updateUserBlockStatus(user.uid, false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn ? 'ইউজার সফলভাবে আনব্লক করা হয়েছে!' : 'User unblocked successfully!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: Text(isBn ? 'আনব্লক করুন' : 'Unblock', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // User is NOT blocked -> Show Suspend dialog with preset reason selection & custom field
    final List<String> presetReasons = isBn
        ? ['স্প্যাম বা ভুয়া বিজ্ঞাপন', 'অশোভন আচরণ / হয়রানি', 'প্রতারণা / সন্দেহজনক লেনদেন', 'শর্তাবলী লঙ্ঘন', 'অন্যান্য']
        : ['Spam or Fake Listing', 'Harassment / Abusive Behavior', 'Fraud / Advance Rent Scam', 'Terms Violation', 'Other'];

    String selectedPreset = presetReasons[0];
    final reasonController = TextEditingController(text: presetReasons[0]);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dialogBg = isDark ? const Color(0xFF0F201D) : Colors.white;
          final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
          final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.block_flipped, color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBn ? 'ইউজার একাউন্ট সাসপেন্ড / ব্লক' : 'Suspend / Block User Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: titleColor),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBn
                        ? 'ইউজার: $name (${user.userType})\nসাসপেন্ড করলে ইউজার কোনো নতুন পোস্ট, চাহিদা বা যোগাযোগ করতে পারবেন না।'
                        : 'User: $name (${user.userType})\nSuspending will restrict the user from creating posts, demands, or interactions.',
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: subtitleColor),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isBn ? 'সাসপেন্ডের কারণ সিলেক্ট করুন:' : 'Select Suspension Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: titleColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presetReasons.map((preset) {
                      final isSelected = selectedPreset == preset;
                      return ChoiceChip(
                        label: Text(preset, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        selectedColor: AppColors.themeColor.withValues(alpha: 0.25),
                        onSelected: (val) {
                          if (val) {
                            setDialogState(() {
                              selectedPreset = preset;
                              reasonController.text = preset;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBn ? 'নির্দিষ্ট কারণ / মন্তব্য লিখুন:' : 'Specific Reason / Remark:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: titleColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: TextStyle(fontSize: 13, color: titleColor),
                    decoration: InputDecoration(
                      hintText: isBn ? 'কারণ লিখুন...' : 'Enter reason...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isBn ? 'বাতিল' : 'Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isBn ? 'অনুগ্রহ করে কারণ লিখুন।' : 'Please enter a reason.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await _adminService.updateUserBlockStatus(user.uid, true, reason: reason);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBn ? 'ইউজার একাউন্ট সফলভাবে সাসপেন্ড করা হয়েছে।' : 'User account suspended.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: Text(isBn ? 'সাসপেন্ড নিশ্চিত করুন' : 'Confirm Suspend', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRejectAppealDialog(BuildContext context, UserModel user, bool isBn, bool isDark) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F201D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? 'আনব্লক আবেদন বাতিল' : 'Reject Reclaim Appeal',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn
                  ? 'ইউজারকে আবেদন বাতিলের কারণ বা সংশোধনের নির্দেশ দিন:'
                  : 'Provide feedback to the user on why their appeal was rejected:',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isBn
                    ? 'যেমন: প্রদত্ত যোগাযোগের তথ্য সঠিক নয় / পুনরায় যাচাই প্রয়োজন...'
                    : 'Enter rejection reason...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final fb = feedbackController.text.trim();
              Navigator.pop(ctx);
              await _adminService.resolveUserAppeal(user.uid, approve: false, adminFeedback: fb);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn ? 'আবেদন বাতিল করা হয়েছে ও ফিডব্যাক পাঠানো হয়েছে।' : 'Appeal rejected and feedback sent.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(isBn ? 'বাতিল নিশ্চিত করুন' : 'Confirm Reject', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, UserModel user, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'ইউজার মুছে ফেলুন' : 'Delete User'),
        content: Text(isBn ? 'আপনি কি নিশ্চিত যে এই ইউজারকে স্থায়ীভাবে ডিলিট করতে চান?' : 'Are you sure you want to permanently delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.deleteUser(user.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'ইউজার সফলভাবে মুছে ফেলা হয়েছে।' : 'User deleted successfully.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'ডিলিট' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String src, double width, double height) {
    if (src.isEmpty) {
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
    if (src.startsWith('data:image') || src.startsWith('/9j/') || src.startsWith('iVBOR') || src.length > 255) {
      try {
        final base64Str = src.contains(',') ? src.split(',').last : src;
        return Image.memory(base64Decode(base64Str.trim()), width: width, height: height, fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 20);
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(src, width: width, height: height, fit: BoxFit.cover);
    } else {
      try {
        if (!kIsWeb && File(src).existsSync()) {
          return Image.file(File(src), width: width, height: height, fit: BoxFit.cover);
        }
      } catch (_) {}
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
  }
}
