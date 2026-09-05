import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../home/data/models/property_model.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../data/services/admin_firestore_service.dart';
import 'admin_post_details_dialog.dart';

class AdminUserPostsDialog extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String userType;
  final bool isBn;
  final bool isDark;

  const AdminUserPostsDialog({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userType,
    required this.isBn,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String userEmail,
    String? userName,
    String? userType,
    required bool isBn,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AdminUserPostsDialog(
        userId: userId,
        userEmail: userEmail,
        userName: userName ?? userEmail.split('@').first,
        userType: userType ?? 'User',
        isBn: isBn,
        isDark: isDark,
      ),
    );
  }

  @override
  State<AdminUserPostsDialog> createState() => _AdminUserPostsDialogState();
}

class _AdminUserPostsDialogState extends State<AdminUserPostsDialog> with SingleTickerProviderStateMixin {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final headerBg = isDark ? const Color(0xFF142C27) : const Color(0xFFF1F8F6);
    final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final String localizedUserType = (widget.userType.toLowerCase().contains('house') || widget.userType.toLowerCase().contains('owner'))
        ? (isBn ? 'বাড়িওয়ালা' : 'House Owner')
        : ((widget.userType.toLowerCase().contains('tenant'))
            ? (isBn ? 'ভাড়াটিয়া' : 'Tenant')
            : (widget.userType.isNotEmpty ? widget.userType : (isBn ? 'ইউজার' : 'User')));

    return Dialog(
      backgroundColor: modalBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<PropertyModel>>(
          stream: _adminService.streamAllProperties(),
          builder: (context, propSnapshot) {
            return StreamBuilder<List<TenantDemandModel>>(
              stream: _adminService.streamAllDemands(),
              builder: (context, demandSnapshot) {
                final allProps = propSnapshot.data ?? [];
                final allDemands = demandSnapshot.data ?? [];

                // Filter for this user
                final userProps = allProps.where((p) {
                  return (widget.userId.isNotEmpty && p.ownerId == widget.userId) ||
                      (widget.userEmail.isNotEmpty && p.ownerEmail.toLowerCase() == widget.userEmail.toLowerCase());
                }).toList();

                final userDemands = allDemands.where((d) {
                  return (widget.userId.isNotEmpty && d.tenantId == widget.userId) ||
                      (widget.userEmail.isNotEmpty && d.tenantEmail.toLowerCase() == widget.userEmail.toLowerCase());
                }).toList();

                final totalPosts = userProps.length + userDemands.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header
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
                              child: const Icon(Icons.dynamic_feed_rounded, color: AppColors.themeColor, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBn ? 'ইউজারের সকল পোস্ট তালিকা' : 'User All Posts',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: titleColor,
                                  ),
                                ),
                                Text(
                                  isBn
                                      ? 'মোট ${totalPosts.toString().toLocalizedDigits(languageCode)} টি পোস্ট পাওয়া গেছে'
                                      : 'Total $totalPosts posts found',
                                  style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: subtitleColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // User Info Header Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: headerBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.themeColor.withValues(alpha: isDark ? 0.3 : 0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.themeColor.withValues(alpha: 0.2),
                            child: const Icon(Icons.person_rounded, color: AppColors.themeColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: titleColor),
                                ),
                                Text(
                                  widget.userEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.5, color: subtitleColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              localizedUserType,
                              style: const TextStyle(
                                color: AppColors.themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.themeColor,
                      unselectedLabelColor: subtitleColor,
                      indicatorColor: AppColors.themeColor,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.home_work_rounded, size: 17),
                              const SizedBox(width: 6),
                              Text(isBn ? 'বাসাভাড়া বিজ্ঞাপন (${userProps.length.toString().toLocalizedDigits(languageCode)})' : 'Listings (${userProps.length})'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.campaign_rounded, size: 17),
                              const SizedBox(width: 6),
                              Text(isBn ? 'ভাড়াটিয়া চাহিদা (${userDemands.length.toString().toLocalizedDigits(languageCode)})' : 'Demands (${userDemands.length})'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Properties
                          userProps.isEmpty
                              ? _buildEmptyState(
                                  icon: Icons.home_outlined,
                                  message: isBn ? 'কোনো বাসাভাড়া বিজ্ঞাপন পোস্ট করা হয়নি' : 'No house listings posted yet',
                                  isDark: isDark,
                                )
                              : ListView.separated(
                                  itemCount: userProps.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) => _buildPropertyCard(userProps[idx], isBn, languageCode, isDark),
                                ),

                          // Tab 2: Demands
                          userDemands.isEmpty
                              ? _buildEmptyState(
                                  icon: Icons.campaign_outlined,
                                  message: isBn ? 'কোনো চাহিদা পোস্ট করা হয়নি' : 'No demand posts created yet',
                                  isDark: isDark,
                                )
                              : ListView.separated(
                                  itemCount: userDemands.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) => _buildDemandCard(userDemands[idx], isBn, languageCode, isDark),
                                ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message, required bool isDark}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property, bool isBn, String languageCode, bool isDark) {
    final cardBg = isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final l10n = context.localizations;

    final status = property.approvalStatus;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusLabel = isBn ? 'অনুমোদিত' : 'Approved';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusLabel = isBn ? 'প্রত্যাখ্যাত' : 'Rejected';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.amber.shade800;
      statusLabel = isBn ? 'পেন্ডিং / পর্যালোচনায়' : 'Pending Review';
      statusIcon = Icons.hourglass_top_rounded;
    }

    final rentText = isBn
        ? '${property.amount.toString().toLocalizedDigits(languageCode)} ৳ / মাস • ${property.month.getLocalizedMonth(l10n)} • ${property.houseType.getLocalizedLabel(l10n)}'
        : '৳ ${property.amount} / month • ${property.month.getLocalizedMonth(l10n)} • ${property.houseType.getLocalizedLabel(l10n)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: property.images.isNotEmpty
                      ? _buildImage(property.images.first, 64, 64)
                      : Container(color: Colors.grey[300], child: const Icon(Icons.home, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            property.shortAddress.isNotEmpty ? property.shortAddress : property.houseType.getLocalizedLabel(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: titleColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: statusColor),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rentText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${property.area.getLocalizedName(languageCode)}, ${property.district.getLocalizedName(languageCode)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (property.isRejected && (property.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${isBn ? "প্রত্যাখ্যানের কারণ" : "Rejection Reason"}: ${property.rejectionReason}',
                style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 6),
          // Action Buttons
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF0284C7)),
                label: Text(isBn ? 'ডিটেইলস' : 'Details', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                onPressed: () {
                  AdminPostDetailsDialog.showPropertyDetails(
                    context,
                    property,
                    isBn: isBn,
                    isDark: isDark,
                  );
                },
              ),
              if (property.approvalStatus != 'approved')
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 13),
                  label: Text(isBn ? 'অনুমোদন' : 'Approve', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    await _adminService.updatePropertyApproval(property.id, 'approved');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isBn ? 'বিজ্ঞাপনটি অনুমোদিত হয়েছে!' : 'Property Approved!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
              if (property.approvalStatus != 'rejected')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 13),
                  label: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showRejectDialog(property.id, isProperty: true, isBn: isBn),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                tooltip: isBn ? 'মুছে ফেলুন' : 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _showDeleteDialog(property.id, isProperty: true, isBn: isBn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemandCard(TenantDemandModel demand, bool isBn, String languageCode, bool isDark) {
    final cardBg = isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final l10n = context.localizations;

    final status = demand.approvalStatus;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusLabel = isBn ? 'অনুমোদিত' : 'Approved';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusLabel = isBn ? 'প্রত্যাখ্যাত' : 'Rejected';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.amber.shade800;
      statusLabel = isBn ? 'পেন্ডিং / পর্যালোচনায়' : 'Pending Review';
      statusIcon = Icons.hourglass_top_rounded;
    }

    final budgetText = demand.budgetRange != null
        ? (isBn ? 'বাজেট: ৳ ${demand.budgetRange!.toLocalizedDigits(languageCode)}' : 'Budget: ৳ ${demand.budgetRange}')
        : (isBn ? 'বাজেট নির্ধারিত নেই' : 'Budget not set');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded, color: AppColors.themeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${demand.houseType.getLocalizedLabel(l10n)} - ${demand.month.getLocalizedMonth(l10n)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: titleColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: statusColor),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      budgetText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${demand.area.getLocalizedName(languageCode)}, ${demand.district.getLocalizedName(languageCode)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: subtitleColor),
                    ),
                    if (demand.detailedDescription.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        demand.detailedDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: subtitleColor, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (demand.isRejected && (demand.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${isBn ? "প্রত্যাখ্যানের কারণ" : "Rejection Reason"}: ${demand.rejectionReason}',
                style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 6),
          // Action Buttons
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF0284C7)),
                label: Text(isBn ? 'ডিটেইলস' : 'Details', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                onPressed: () {
                  AdminPostDetailsDialog.showDemandDetails(
                    context,
                    demand,
                    isBn: isBn,
                    isDark: isDark,
                  );
                },
              ),
              if (demand.approvalStatus != 'approved')
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 13),
                  label: Text(isBn ? 'অনুমোদন' : 'Approve', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    await _adminService.updateDemandApproval(demand.id, 'approved');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isBn ? 'চাহিদা পোস্টটি অনুমোদিত হয়েছে!' : 'Demand Post Approved!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
              if (demand.approvalStatus != 'rejected')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 13),
                  label: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showRejectDialog(demand.id, isProperty: false, isBn: isBn),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                tooltip: isBn ? 'মুছে ফেলুন' : 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _showDeleteDialog(demand.id, isProperty: false, isBn: isBn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String id, {required bool isProperty, required bool isBn}) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'পোস্ট প্রত্যাখ্যানের কারণ' : 'Reject Post'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: isBn ? 'প্রত্যাখ্যানের সুনির্দিষ্ট কারণ লিখুন...' : 'Enter rejection reason...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isProperty) {
                await _adminService.updatePropertyApproval(id, 'rejected', reason: reasonController.text);
              } else {
                await _adminService.updateDemandApproval(id, 'rejected', reason: reasonController.text);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'পোস্টটি প্রত্যাখ্যান করা হয়েছে।' : 'Post rejected.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id, {required bool isProperty, required bool isBn}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'পোস্ট মুছে ফেলুন' : 'Delete Post'),
        content: Text(isBn ? 'আপনি কি নিশ্চিত যে এই পোস্টটি স্থায়ীভাবে ডিলিট করতে চান?' : 'Are you sure you want to permanently delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isProperty) {
                await _adminService.deleteProperty(id);
              } else {
                await _adminService.deleteDemand(id);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'পোস্টটি ডিলিট করা হয়েছে।' : 'Post deleted.'), backgroundColor: Colors.redAccent),
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

