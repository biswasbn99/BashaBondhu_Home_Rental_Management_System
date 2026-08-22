import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

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
              return u.nidFrontImageUrl.isNotEmpty;
            case 'Pending':
              return u.nidFrontImageUrl.isEmpty;
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
                isBn ? 'ইউজার ম্যানেজমেন্ট' : 'User Management',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.themeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBn
                    ? 'বাড়িওয়ালা, ভাড়াটিয়া ও এনআইডি ভেরিফিকেশন ম্যানেজ করুন (${filteredUsers.length} জন ইউজার)'
                    : 'Manage Owners, Tenants, and NID Verifications (${filteredUsers.length} users)',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
              ),
              const SizedBox(height: 20),

              // Search and Filter Bar with Responsive LayoutBuilder
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2625) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
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
                  color: isDark ? const Color(0xFF1E2625) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
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
                            DataColumn(label: Text(isBn ? 'যোগাযোগ' : 'Contact', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'এনআইডি স্ট্যাটাস' : 'NID Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'প্রোফাইল' : 'Profile %', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'অ্যাকশন' : 'Actions', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredUsers.map((user) {
                            final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
                            final isVerified = user.nidFrontImageUrl.isNotEmpty;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.themeColor.withValues(alpha: 0.12),
                                        child: Text(user.initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.themeColor)),
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
                                      color: (user.userType == 'House Owner' ? AppColors.themeColor : Colors.purple).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.userType,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: user.userType == 'House Owner' ? AppColors.themeColor : Colors.purple,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(user.mobile.isNotEmpty ? user.mobile : 'N/A', style: const TextStyle(fontSize: 11.5))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isVerified ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isVerified ? (isBn ? 'ভেরিফাইড' : 'Verified') : (isBn ? 'পেন্ডিং' : 'Pending'),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isVerified ? Colors.green : Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${user.profileCompletionPercentage}%',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: user.profileCompletionPercentage == 100 ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.blueAccent),
                                        tooltip: isBn ? 'ডিটেইলস দেখুন' : 'View Details',
                                        onPressed: () => _showUserDetailsModal(context, user, isBn),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.verified_user_outlined, size: 18, color: Colors.green),
                                        tooltip: isBn ? 'ভেরিফাই করুন' : 'Verify NID',
                                        onPressed: () => _showVerifyNidDialog(context, user, isBn),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.block_flipped, size: 18, color: Colors.orange),
                                        tooltip: isBn ? 'ব্লক / আনব্লক' : 'Block / Unblock',
                                        onPressed: () => _showBlockDialog(context, user, isBn),
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

  Widget _buildFilterDropdown(bool isBn, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C1B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: 'All', child: Text(isBn ? 'সকল ইউজার (All)' : 'All Users')),
            DropdownMenuItem(value: 'Owners', child: Text(isBn ? 'বাড়িওয়ালা (Owners)' : 'House Owners')),
            DropdownMenuItem(value: 'Tenants', child: Text(isBn ? 'ভাড়াটিয়া (Tenants)' : 'Tenants')),
            DropdownMenuItem(value: 'Verified', child: Text(isBn ? 'ভেরিফাইড (Verified)' : 'NID Verified')),
            DropdownMenuItem(value: 'Pending', child: Text(isBn ? 'পেন্ডিং (Pending)' : 'NID Pending')),
          ],
          onChanged: (val) => setState(() => _selectedFilter = val!),
        ),
      ),
    );
  }

  void _showUserDetailsModal(BuildContext context, UserModel user, bool isBn) {
    final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isBn ? 'ইউজার প্রোফাইল বিবরণ' : 'User Profile Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.themeColor.withValues(alpha: 0.12),
                      child: user.profileImageUrl.isNotEmpty
                          ? ClipOval(child: _buildImage(user.profileImageUrl, 60, 60))
                          : Text(user.initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.themeColor)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isNotEmpty ? name : 'User', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${user.userType} • ${user.mobile.isNotEmpty ? user.mobile : "No Phone"}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('UID', user.uid),
                _buildInfoRow(isBn ? 'লিঙ্গ' : 'Gender', user.gender.isNotEmpty ? user.gender : 'N/A'),
                _buildInfoRow(isBn ? 'জন্ম তারিখ' : 'Date of Birth', user.dateOfBirth.isNotEmpty ? user.dateOfBirth : 'N/A'),
                _buildInfoRow(isBn ? 'প্রোফাইল সম্পূর্ণতা' : 'Profile Completion', '${user.profileCompletionPercentage}%'),
                _buildInfoRow(isBn ? 'যোগদানের তারিখ' : 'Registered Date', user.createdAt),
                const SizedBox(height: 16),
                Text(isBn ? 'জাতীয় পরিচয়পত্র (NID Images):' : 'National ID (NID Images):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isBn ? 'সামনের দিক (Front):' : 'Front Side:', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            height: 110,
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                            child: user.nidFrontImageUrl.isNotEmpty
                                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildImage(user.nidFrontImageUrl, double.infinity, 110))
                                : const Center(child: Text('No Image', style: TextStyle(color: Colors.grey, fontSize: 11))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isBn ? 'পেছনের দিক (Back):' : 'Back Side:', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            height: 110,
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                            child: user.nidBackImageUrl.isNotEmpty
                                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildImage(user.nidBackImageUrl, double.infinity, 110))
                                : const Center(child: Text('No Image', style: TextStyle(color: Colors.grey, fontSize: 11))),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerifyNidDialog(BuildContext context, UserModel user, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'এনআইডি ভেরিফিকেশন অনুমোদন' : 'Approve NID Verification'),
        content: Text(isBn ? 'আপনি কি ${user.fullName} এর এনআইডি ভেরিফিকেশন অনুমোদন করতে চান?' : 'Do you want to verify NID for ${user.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.updateUserNidStatus(user.uid, 'verified');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'এনআইডি সফলভাবে ভেরিফাই করা হয়েছে!' : 'NID Verified Successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text(isBn ? 'অনুমোদন' : 'Verify'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, UserModel user, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'ইউজার ব্লক / সাসপেন্ড' : 'Block / Suspend User'),
        content: Text(isBn ? 'আপনি কি এই ইউজারকে ব্লক করতে চান?' : 'Are you sure you want to toggle block status for this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.updateUserBlockStatus(user.uid, true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'ইউজারকে ব্লক করা হয়েছে।' : 'User blocked.'), backgroundColor: Colors.orange),
                );
              }
            },
            child: Text(isBn ? 'ব্লক করুন' : 'Block'),
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
    if (src.startsWith('data:image')) {
      try {
        final base64Str = src.split(',').last;
        return Image.memory(base64Decode(base64Str), width: width, height: height, fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 20);
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(src, width: width, height: height, fit: BoxFit.cover);
    } else {
      return Image.file(File(src), width: width, height: height, fit: BoxFit.cover);
    }
  }
}
