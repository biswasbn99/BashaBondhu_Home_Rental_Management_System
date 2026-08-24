import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;
    final adminService = AdminFirestoreService();

    return StreamBuilder<List<UserModel>>(
      stream: adminService.streamAllUsers(),
      builder: (context, userSnapshot) {
        final users = userSnapshot.data ?? [];

        return StreamBuilder<List<PropertyModel>>(
          stream: adminService.streamAllProperties(),
          builder: (context, propSnapshot) {
            final properties = propSnapshot.data ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: adminService.streamReports(),
              builder: (context, reportSnapshot) {
                final reports = reportSnapshot.data ?? [];

                // Metrics Calculation
                final int totalUsers = users.length;
                final int totalOwners = users.where((u) => u.userType == 'House Owner').length;
                final int totalTenants = users.where((u) => u.userType == 'Tenant').length;
                final int totalVerified = users.where((u) => u.nidFrontImageUrl.isNotEmpty).length;

                final int totalProperties = properties.length;
                final int pendingProperties = properties.where((p) => !p.isAvailable || p.month == 'Pending').length;
                final int approvedProperties = properties.where((p) => p.isAvailable).length;
                final int rejectedProperties = properties.where((p) => !p.isAvailable && p.month == 'Rejected').length;

                final int totalReports = reports.length;

                // Pending Verification Users
                final pendingUsers = users.where((u) => u.nidFrontImageUrl.isNotEmpty).take(5).toList();
                // Recent Properties
                final recentProperties = properties.take(5).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Responsive Wrap
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? 'অ্যাডমিন ড্যাশবোর্ড ওভারভিউ' : 'Dashboard Overview',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.themeColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBn
                                    ? 'স্বাগতম, অ্যাডমিন। রিয়েল-টাইম সিস্টেম ডেটা ও পরিসংখ্যান।'
                                    : 'Welcome back, Admin. Real-time statistics from Cloud Firestore.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isBn ? 'বাংলা' : 'English',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Switch.adaptive(
                                  value: isBn,
                                  activeTrackColor: AppColors.themeColor,
                                  onChanged: (_) => adminProvider.toggleLanguage(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // User Statistics Group
                      _buildSectionTitle(isBn ? '👥 ইউজার পরিসংখ্যান (Users Analytics)' : '👥 Users Analytics', isDark),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final int crossAxisCount = constraints.maxWidth > 950 ? 4 : (constraints.maxWidth > 580 ? 2 : 1);
                          final double aspectRatio = constraints.maxWidth > 950 ? 1.5 : (constraints.maxWidth > 580 ? 1.4 : 2.2);

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: aspectRatio,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _StatCard(
                                title: isBn ? 'মোট ইউজার' : 'Total Users',
                                value: totalUsers.toString(),
                                icon: Icons.people_alt_rounded,
                                color: Colors.blueAccent,
                                isDark: isDark,
                              ),
                              _StatCard(
                                title: isBn ? 'মোট বাড়িওয়ালা' : 'Total Owners',
                                value: totalOwners.toString(),
                                icon: Icons.home_work_rounded,
                                color: AppColors.themeColor,
                                isDark: isDark,
                              ),
                              _StatCard(
                                title: isBn ? 'মোট ভাড়াটিয়া' : 'Total Tenants',
                                value: totalTenants.toString(),
                                icon: Icons.person_pin_circle_rounded,
                                color: Colors.purple,
                                isDark: isDark,
                              ),
                              _StatCard(
                                title: isBn ? 'ভেরিফাইড ইউজার' : 'Verified Users',
                                value: totalVerified.toString(),
                                icon: Icons.verified_user_rounded,
                                color: Colors.teal,
                                isDark: isDark,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Property & Reports Statistics Group
                      _buildSectionTitle(isBn ? '🏠 প্রপার্টি ও রিপোর্ট পরিসংখ্যান (Listings & Reports)' : '🏠 Properties & Reports', isDark),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final int crossAxisCount = constraints.maxWidth > 1100 ? 5 : (constraints.maxWidth > 750 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));
                          final double aspectRatio = constraints.maxWidth > 1100 ? 1.45 : (constraints.maxWidth > 750 ? 1.4 : (constraints.maxWidth > 500 ? 1.35 : 2.2));

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: aspectRatio,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _StatCard(
                                title: isBn ? 'মোট বাসা' : 'Total Properties',
                                value: totalProperties.toString(),
                                icon: Icons.apartment_rounded,
                                color: Colors.indigo,
                                isDark: isDark,
                              ),
                              _StatCard(
                                title: isBn ? 'অনুমোদিত বাসা' : 'Approved Houses',
                                value: approvedProperties.toString(),
                                icon: Icons.check_circle_outline_rounded,
                                color: Colors.green,
                                isDark: isDark,
                              ),
                              _StatCard(
                                title: isBn ? 'পেন্ডিং বাসা' : 'Pending Houses',
                                value: pendingProperties.toString(),
                                icon: Icons.pending_actions_rounded,
                                color: Colors.amber.shade800,
                                isDark: isDark,
                              ),
                              _StatCard(
                                title: isBn ? 'প্রত্যাখ্যাত বাসা' : 'Rejected Houses',
                                value: rejectedProperties.toString(),
                                icon: Icons.cancel_outlined,
                                color: Colors.deepOrange,
                                isDark: isDark,
                              ),
                              _StatCard(
                                title: isBn ? 'মোট রিপোর্ট' : 'Total Reports',
                                value: totalReports.toString(),
                                icon: Icons.report_problem_rounded,
                                color: Colors.redAccent,
                                isDark: isDark,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // Tables Section (Recent Submissions & Pending Verifications)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 850) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _buildRecentPropertiesCard(context, recentProperties, isBn, isDark, adminService),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 5,
                                  child: _buildPendingVerificationsCard(context, pendingUsers, isBn, isDark, adminService),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildRecentPropertiesCard(context, recentProperties, isBn, isDark, adminService),
                                const SizedBox(height: 20),
                                _buildPendingVerificationsCard(context, pendingUsers, isBn, isDark, adminService),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRecentPropertiesCard(
    BuildContext context,
    List<PropertyModel> properties,
    bool isBn,
    bool isDark,
    AdminFirestoreService adminService,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  isBn ? 'সাম্প্রতিক বাসাভাড়ার বিজ্ঞাপন' : 'Recent Submissions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () => context.read<AdminProvider>().changeModule(AdminModule.properties),
                child: Text(isBn ? 'সব দেখুন' : 'View All'),
              ),
            ],
          ),
          const Divider(height: 12),
          if (properties.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  isBn ? 'কোনো বিজ্ঞাপন পাওয়া যায়নি' : 'No recent submissions',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            )
          else
            Column(
              children: properties.map((prop) {
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: prop.images.isNotEmpty
                            ? _buildImage(prop.images.first, 44, 44)
                            : Container(color: Colors.grey[300], child: const Icon(Icons.home, size: 20)),
                      ),
                    ),
                    title: Text(
                      prop.shortAddress.isNotEmpty ? prop.shortAddress : prop.houseType.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      "${prop.amount} ৳ • ${prop.area.name}, ${prop.district.name}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.themeColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          tooltip: isBn ? 'অনুমোদন করুন' : 'Approve',
                          onPressed: () async {
                            await adminService.updatePropertyApproval(prop.id, 'approved');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isBn ? 'বিজ্ঞাপনটি অনুমোদিত হয়েছে!' : 'Property approved!'), backgroundColor: Colors.green),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
                          tooltip: isBn ? 'প্রত্যাখ্যান করুন' : 'Reject',
                          onPressed: () => _showRejectDialog(context, prop.id, adminService, isBn),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationsCard(
    BuildContext context,
    List<UserModel> users,
    bool isBn,
    bool isDark,
    AdminFirestoreService adminService,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  isBn ? 'এনআইডি ভেরিফিকেশন আবেদন' : 'Pending Verifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () => context.read<AdminProvider>().changeModule(AdminModule.users),
                child: Text(isBn ? 'সব দেখুন' : 'View All'),
              ),
            ],
          ),
          const Divider(height: 12),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  isBn ? 'কোনো পেন্ডিং ভেরিফিকেশন নেই' : 'No pending verifications',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            )
          else
            Column(
              children: users.map((user) {
                final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.themeColor.withValues(alpha: 0.12),
                      child: Text(user.initials, style: const TextStyle(color: AppColors.themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    title: Text(name.isNotEmpty ? name : 'User', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      '${user.userType} • ${user.mobile.isNotEmpty ? user.mobile : user.email}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await adminService.updateUserNidStatus(user.uid, 'verified');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isBn ? 'এনআইডি ভেরিফাইড সম্পন্ন হয়েছে!' : 'User NID Verified!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: Text(isBn ? 'ভেরিফাই' : 'Verify', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String propertyId, AdminFirestoreService adminService, bool isBn) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'বিজ্ঞাপন প্রত্যাখ্যানের কারণ' : 'Reject Property Listing'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: isBn ? 'প্রত্যাখ্যানের কারণ লিখুন' : 'Enter rejection reason',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await adminService.updatePropertyApproval(propertyId, 'rejected', reason: reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'বিজ্ঞাপনটি প্রত্যাখ্যান করা হয়েছে।' : 'Property rejected.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'প্রত্যাখ্যান করুন' : 'Reject'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
