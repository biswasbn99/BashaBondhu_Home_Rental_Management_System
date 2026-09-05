import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../home/data/models/property_model.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';
import '../widgets/admin_post_details_dialog.dart';
import '../widgets/admin_user_posts_dialog.dart';

enum PostCategoryFilter {
  all,
  properties,
  demands,
  pending,
  approved,
  rejected,
}

class _AdminPostEntry {
  final PropertyModel? property;
  final TenantDemandModel? demand;
  final DateTime postDate;

  _AdminPostEntry.fromProperty(PropertyModel p)
      : property = p,
        demand = null,
        postDate = p.postDate;

  _AdminPostEntry.fromDemand(TenantDemandModel d)
      : property = null,
        demand = d,
        postDate = d.postDate;

  bool get isProperty => property != null;
}

class PropertyManagementView extends StatefulWidget {
  const PropertyManagementView({super.key});

  @override
  State<PropertyManagementView> createState() => _PropertyManagementViewState();
}

class _PropertyManagementViewState extends State<PropertyManagementView> {
  String _selectedFilter = 'All';
  String _selectedSort = 'newest'; // 'newest', 'oldest', 'date_filter'
  DateTime? _filterDate;
  int? _filterMonth;
  int? _filterYear;
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

    final cardBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return StreamBuilder<bool>(
      stream: _adminService.streamAutoApprovalSetting(),
      builder: (_, autoApproveSnapshot) {
        final isAutoApprovalOn = autoApproveSnapshot.data ?? true;

        return StreamBuilder<List<PropertyModel>>(
          stream: _adminService.streamAllProperties(),
          builder: (_, propSnapshot) {
            return StreamBuilder<List<TenantDemandModel>>(
              stream: _adminService.streamAllDemands(),
              builder: (_, demandSnapshot) {
                final allProperties = propSnapshot.data ?? [];
                final allDemands = demandSnapshot.data ?? [];

                // Filter Properties
                final filteredProperties = allProperties.where((p) {
                  if (_selectedFilter == 'Demands') return false;
                  if (_selectedFilter == 'Pending' && p.approvalStatus != 'pending') return false;
                  if (_selectedFilter == 'Approved' && p.approvalStatus != 'approved') return false;
                  if (_selectedFilter == 'Rejected' && p.approvalStatus != 'rejected') return false;

                  if (!_matchesDateFilter(p.postDate)) return false;

                  final query = _searchQuery.toLowerCase();
                  if (query.isEmpty) return true;

                  final address = p.shortAddress.toLowerCase();
                  final owner = p.ownerEmail.toLowerCase();
                  final type = p.houseType.name.toLowerCase();
                  final area = p.area.name.toLowerCase();
                  final district = p.district.name.toLowerCase();

                  return address.contains(query) ||
                      owner.contains(query) ||
                      type.contains(query) ||
                      area.contains(query) ||
                      district.contains(query) ||
                      _matchesDateQuery(p.postDate, p.month, query);
                }).toList();

                // Filter Demands
                final filteredDemands = allDemands.where((d) {
                  if (_selectedFilter == 'Properties') return false;
                  if (_selectedFilter == 'Pending' && d.approvalStatus != 'pending') return false;
                  if (_selectedFilter == 'Approved' && d.approvalStatus != 'approved') return false;
                  if (_selectedFilter == 'Rejected' && d.approvalStatus != 'rejected') return false;

                  if (!_matchesDateFilter(d.postDate)) return false;

                  final query = _searchQuery.toLowerCase();
                  if (query.isEmpty) return true;

                  final notes = d.detailedDescription.toLowerCase();
                  final email = d.tenantEmail.toLowerCase();
                  final type = d.houseType.name.toLowerCase();
                  final area = d.area.name.toLowerCase();
                  final district = d.district.name.toLowerCase();

                  return notes.contains(query) ||
                      email.contains(query) ||
                      type.contains(query) ||
                      area.contains(query) ||
                      district.contains(query) ||
                      _matchesDateQuery(d.postDate, d.month, query);
                }).toList();

                // Combine into unified sorted list
                final List<_AdminPostEntry> combinedPosts = [
                  ...filteredProperties.map((p) => _AdminPostEntry.fromProperty(p)),
                  ...filteredDemands.map((d) => _AdminPostEntry.fromDemand(d)),
                ];

                if (_selectedSort == 'oldest') {
                  combinedPosts.sort((a, b) => a.postDate.compareTo(b.postDate));
                } else {
                  // 'newest' or 'date_filter' (newest first by default)
                  combinedPosts.sort((a, b) => b.postDate.compareTo(a.postDate));
                }

                final totalResults = combinedPosts.length;
                final isDateFilterActive = _filterDate != null || _filterMonth != null || _filterYear != null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? 'পোস্ট ও বিজ্ঞাপন ম্যানেজমেন্ট' : 'Post & Property Management',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.themeColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBn
                                    ? 'বাড়িভাড়া ও চাহিদা পোস্ট অনুমোদন, প্রত্যাখ্যান ও ইউজার পোস্ট দেখুন ($totalResults টি পোস্ট)'
                                    : 'Review, Approve, Reject and manage listings & demands ($totalResults items)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- AUTO APPROVAL TOGGLE CARD ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAutoApprovalOn
                                ? (isDark
                                    ? [const Color(0xFF0F382E), const Color(0xFF0B2620)]
                                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)])
                                : (isDark
                                    ? [const Color(0xFF38260F), const Color(0xFF26190B)]
                                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAutoApprovalOn
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : Colors.amber.shade700.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isAutoApprovalOn
                                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                    : Colors.amber.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAutoApprovalOn ? Icons.auto_mode_rounded : Icons.pending_actions_rounded,
                                color: isAutoApprovalOn ? const Color(0xFF10B981) : Colors.amber.shade800,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isBn ? 'স্বয়ংক্রিয় অনুমোদন (Auto-Approval System)' : 'Auto-Approval System',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14.5,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isAutoApprovalOn
                                              ? const Color(0xFF10B981)
                                              : Colors.amber.shade800,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isAutoApprovalOn
                                              ? (isBn ? 'অন (চালু)' : 'ON')
                                              : (isBn ? 'অফ (বন্ধ)' : 'OFF'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isAutoApprovalOn
                                        ? (isBn
                                            ? 'চালু রয়েছে: ইউজাররা পোস্ট করার সাথে সাথে বিজ্ঞাপন সরাসরি লাইভ হবে।'
                                            : 'Enabled: New listings and demands are automatically approved and live immediately.')
                                        : (isBn
                                            ? 'বন্ধ রয়েছে: পোস্টগুলো পেন্ডিং থাকবে, অ্যাডমিন অনুমোদন না করা পর্যন্ত অন্য কেউ দেখতে পাবে না।'
                                            : 'Disabled: New posts require manual admin approval before becoming publicly visible.'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Switch.adaptive(
                              value: isAutoApprovalOn,
                              activeThumbColor: const Color(0xFF10B981),
                              onChanged: (val) async {
                                final messenger = ScaffoldMessenger.of(context);
                                await _adminService.toggleAutoApproval(val);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      val
                                          ? (isBn ? 'স্বয়ংক্রিয় অনুমোদন চালু করা হয়েছে!' : 'Auto-Approval Enabled!')
                                          : (isBn ? 'স্বয়ংক্রিয় অনুমোদন বন্ধ করা হয়েছে (ম্যানুয়াল রিভিউ মোড সক্রিয়)!' : 'Auto-Approval Disabled (Manual Review Mode)!'),
                                    ),
                                    backgroundColor: val ? const Color(0xFF10B981) : Colors.orange,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Search, Category Filter & Sort Dropdown Bar
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 780) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (val) => setState(() => _searchQuery = val),
                                          decoration: InputDecoration(
                                            hintText: isBn
                                                ? 'লোকেশন, ইমেইল, তারিখ (দিন/মাস/বছর) দিয়ে খুঁজুন...'
                                                : 'Search by Address, Email, Date (DD/MM/YYYY)...',
                                            prefixIcon: const Icon(Icons.search_rounded),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildFilterDropdown(isBn, isDark),
                                      const SizedBox(width: 10),
                                      _buildSortDropdown(isBn, isDark),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _searchController,
                                        onChanged: (val) => setState(() => _searchQuery = val),
                                        decoration: InputDecoration(
                                          hintText: isBn
                                              ? 'লোকেশন, ইমেইল, তারিখ দিয়ে খুঁজুন...'
                                              : 'Search by Address, Email, Date...',
                                          prefixIcon: const Icon(Icons.search_rounded),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _buildFilterDropdown(isBn, isDark),
                                          _buildSortDropdown(isBn, isDark),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),

                            // Active Date Filter Badge
                            if (isDateFilterActive) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getActiveFilterText(isBn),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _filterDate = null;
                                          _filterMonth = null;
                                          _filterYear = null;
                                          _selectedSort = 'newest';
                                        });
                                      },
                                      child: const Icon(Icons.cancel_rounded, size: 16, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Posts DataTable
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: totalResults == 0
                            ? Padding(
                                padding: const EdgeInsets.all(40),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.home_work_outlined, size: 44, color: Colors.grey),
                                      const SizedBox(height: 10),
                                      Text(
                                        isBn ? 'কোনো পোস্ট বা বিজ্ঞাপন পাওয়া যায়নি' : 'No posts found matching query',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: titleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  dataRowMinHeight: 64,
                                  dataRowMaxHeight: 74,
                                  columnSpacing: 20,
                                  horizontalMargin: 16,
                                  columns: [
                                    DataColumn(label: Text(isBn ? 'পোস্ট ও শিরোনাম' : 'Post / Title', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))),
                                    DataColumn(label: Text(isBn ? 'পোস্টের ধরন' : 'Category', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))),
                                    DataColumn(label: Text(isBn ? 'পোস্টকারী' : 'Poster', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))),
                                    DataColumn(label: Text(isBn ? 'ভাড়া / বাজেট' : 'Rent / Budget', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))),
                                    DataColumn(label: Text(isBn ? 'লোকেশন' : 'Location', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))),
                                    DataColumn(label: Text(isBn ? 'স্ট্যাটাস' : 'Status', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))),
                                    DataColumn(label: Text(isBn ? 'অ্যাকশন' : 'Actions', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))),
                                  ],
                                  rows: combinedPosts.map((entry) {
                                    if (entry.isProperty) {
                                      return _buildPropertyDataRow(entry.property!, isBn, isDark, titleColor, subtitleColor);
                                    } else {
                                      return _buildDemandDataRow(entry.demand!, isBn, isDark, titleColor, subtitleColor);
                                    }
                                  }).toList(),
                                ),
                              ),
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

  DataRow _buildPropertyDataRow(
    PropertyModel property,
    bool isBn,
    bool isDark,
    Color titleColor,
    Color subtitleColor,
  ) {
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
      statusLabel = isBn ? 'পেন্ডিং' : 'Pending';
      statusIcon = Icons.hourglass_top_rounded;
    }

    final l10n = context.localizations;
    final languageCode = isBn ? 'bn' : 'en';

    return DataRow(
      cells: [
        // Post Title, Image & Post Date
        DataCell(
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: property.images.isNotEmpty
                      ? _buildImage(property.images.first, 40, 40)
                      : Container(color: Colors.grey[300], child: const Icon(Icons.home, size: 18)),
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
                      property.shortAddress.isNotEmpty ? property.shortAddress : property.houseType.getLocalizedLabel(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: titleColor),
                    ),
                    Text(
                      property.month.getLocalizedMonth(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: subtitleColor),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 10, color: subtitleColor),
                        const SizedBox(width: 3),
                        Text(
                          _formatPostDate(property.postDate, isBn),
                          style: TextStyle(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_work_rounded, size: 12, color: AppColors.themeColor),
                const SizedBox(width: 4),
                Text(
                  isBn ? 'বাড়িভাড়া' : 'Listing',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                ),
              ],
            ),
          ),
        ),

        // Poster (with User Posts Button)
        DataCell(
          InkWell(
            onTap: () => AdminUserPostsDialog.show(
              context,
              userId: property.ownerId,
              userEmail: property.ownerEmail,
              userName: property.contactName.isNotEmpty ? property.contactName : property.ownerEmail.split('@').first,
              userType: 'House Owner',
              isBn: isBn,
              isDark: isDark,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      property.ownerEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF0284C7)),
                        const SizedBox(width: 2),
                        Text(
                          isBn ? 'সব পোস্ট দেখুন' : 'All Posts',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Rent
        DataCell(
          Text(
            isBn
                ? "${property.amount.toString().toLocalizedDigits(languageCode)} ৳"
                : "৳ ${property.amount}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.themeColor),
          ),
        ),

        // Location
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              "${property.area.getLocalizedName(languageCode)}, ${property.district.getLocalizedName(languageCode)}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: titleColor),
            ),
          ),
        ),

        // Status Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 3),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Buttons
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                tooltip: isBn ? 'ডিটেইলস দেখুন' : 'View Details',
                onPressed: () => AdminPostDetailsDialog.showPropertyDetails(context, property, isBn: isBn, isDark: isDark),
              ),
              IconButton(
                icon: const Icon(Icons.dynamic_feed_rounded, size: 18, color: Colors.purple),
                tooltip: isBn ? 'এই ইউজারের সকল পোস্ট' : "View User's All Posts",
                onPressed: () => AdminUserPostsDialog.show(
                  context,
                  userId: property.ownerId,
                  userEmail: property.ownerEmail,
                  userName: property.contactName.isNotEmpty ? property.contactName : property.ownerEmail.split('@').first,
                  userType: 'House Owner',
                  isBn: isBn,
                  isDark: isDark,
                ),
              ),
              if (property.approvalStatus != 'approved')
                IconButton(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                  tooltip: isBn ? 'অনুমোদন করুন' : 'Approve',
                  onPressed: () async {
                    await _adminService.updatePropertyApproval(property.id, 'approved');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isBn ? 'বিজ্ঞাপন অনুমোদিত হয়েছে!' : 'Property Approved!'), backgroundColor: Colors.green),
                    );
                  },
                ),
              if (property.approvalStatus != 'rejected')
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.orange),
                  tooltip: isBn ? 'প্রত্যাখ্যান করুন' : 'Reject',
                  onPressed: () => _showRejectDialog(context, property.id, isProperty: true, isBn: isBn),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                tooltip: isBn ? 'মুছে ফেলুন' : 'Delete Property',
                onPressed: () => _showDeleteDialog(context, property.id, isProperty: true, isBn: isBn),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildDemandDataRow(
    TenantDemandModel demand,
    bool isBn,
    bool isDark,
    Color titleColor,
    Color subtitleColor,
  ) {
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
      statusLabel = isBn ? 'পেন্ডিং' : 'Pending';
      statusIcon = Icons.hourglass_top_rounded;
    }

    final l10n = context.localizations;
    final languageCode = isBn ? 'bn' : 'en';

    return DataRow(
      cells: [
        // Demand Title, Icon & Post Date
        DataCell(
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.campaign_rounded, size: 20, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${demand.houseType.getLocalizedLabel(l10n)} - ${demand.month.getLocalizedMonth(l10n)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: titleColor),
                    ),
                    Text(
                      demand.tenantType?.getLocalizedLabel(l10n) ?? 'Tenant',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: subtitleColor),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 10, color: subtitleColor),
                        const SizedBox(width: 3),
                        Text(
                          _formatPostDate(demand.postDate, isBn),
                          style: TextStyle(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign_rounded, size: 12, color: Color(0xFF0284C7)),
                const SizedBox(width: 4),
                Text(
                  isBn ? 'চাহিদা' : 'Demand',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                ),
              ],
            ),
          ),
        ),

        // Poster (with User Posts Button)
        DataCell(
          InkWell(
            onTap: () => AdminUserPostsDialog.show(
              context,
              userId: demand.tenantId,
              userEmail: demand.tenantEmail,
              userName: demand.userName.isNotEmpty ? demand.userName : demand.tenantEmail.split('@').first,
              userType: 'Tenant',
              isBn: isBn,
              isDark: isDark,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      demand.tenantEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF0284C7)),
                        const SizedBox(width: 2),
                        Text(
                          isBn ? 'সব পোস্ট দেখুন' : 'All Posts',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Budget
        DataCell(
          Text(
            demand.budgetRange != null
                ? (isBn ? "${demand.budgetRange!.toLocalizedDigits(languageCode)} ৳" : "৳ ${demand.budgetRange}")
                : "N/A",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.themeColor),
          ),
        ),

        // Location
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              "${demand.area.getLocalizedName(languageCode)}, ${demand.district.getLocalizedName(languageCode)}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: titleColor),
            ),
          ),
        ),

        // Status Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 3),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Buttons
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                tooltip: isBn ? 'ডিটেইলস দেখুন' : 'View Details',
                onPressed: () => AdminPostDetailsDialog.showDemandDetails(context, demand, isBn: isBn, isDark: isDark),
              ),
              IconButton(
                icon: const Icon(Icons.dynamic_feed_rounded, size: 18, color: Colors.purple),
                tooltip: isBn ? 'এই ইউজারের সকল পোস্ট' : "View User's All Posts",
                onPressed: () => AdminUserPostsDialog.show(
                  context,
                  userId: demand.tenantId,
                  userEmail: demand.tenantEmail,
                  userName: demand.userName.isNotEmpty ? demand.userName : demand.tenantEmail.split('@').first,
                  userType: 'Tenant',
                  isBn: isBn,
                  isDark: isDark,
                ),
              ),
              if (demand.approvalStatus != 'approved')
                IconButton(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                  tooltip: isBn ? 'অনুমোদন করুন' : 'Approve',
                  onPressed: () async {
                    await _adminService.updateDemandApproval(demand.id, 'approved');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isBn ? 'চাহিদা পোস্ট অনুমোদিত হয়েছে!' : 'Demand Approved!'), backgroundColor: Colors.green),
                    );
                  },
                ),
              if (demand.approvalStatus != 'rejected')
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.orange),
                  tooltip: isBn ? 'প্রত্যাখ্যান করুন' : 'Reject',
                  onPressed: () => _showRejectDialog(context, demand.id, isProperty: false, isBn: isBn),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                tooltip: isBn ? 'মুছে ফেলুন' : 'Delete Demand',
                onPressed: () => _showDeleteDialog(context, demand.id, isProperty: false, isBn: isBn),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(bool isBn, bool isDark) {
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
            DropdownMenuItem(value: 'All', child: Text(isBn ? '📋 সকল পোস্ট (All)' : '📋 All Posts')),
            DropdownMenuItem(value: 'Properties', child: Text(isBn ? '🏡 বাসাভাড়া বিজ্ঞাপন (Listings)' : '🏡 House Listings')),
            DropdownMenuItem(value: 'Demands', child: Text(isBn ? '📢 ভাড়াটিয়া চাহিদা (Demands)' : '📢 Tenant Demands')),
            DropdownMenuItem(value: 'Pending', child: Text(isBn ? '⏳ পেন্ডিং অনুমোদন (Pending)' : '⏳ Pending Review')),
            DropdownMenuItem(value: 'Approved', child: Text(isBn ? '✅ অনুমোদিত (Approved)' : '✅ Approved')),
            DropdownMenuItem(value: 'Rejected', child: Text(isBn ? '❌ প্রত্যাখ্যাত (Rejected)' : '❌ Rejected')),
          ],
          onChanged: (val) => setState(() => _selectedFilter = val!),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(bool isBn, bool isDark) {
    final isDateFilterActive = _filterDate != null || _filterMonth != null || _filterYear != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDateFilterActive
              ? const Color(0xFF0284C7)
              : (isDark ? const Color(0xFF223E38) : const Color(0xFFCBD5E1)),
          width: isDateFilterActive ? 1.5 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          items: [
            DropdownMenuItem(
              value: 'newest',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(isBn ? '🕒 সর্বশেষ পোস্ট (Newest)' : '🕒 Newest Post'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'oldest',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(isBn ? '⌛ প্রাচীনতম পোস্ট (Oldest)' : '⌛ Oldest Post'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'date_filter',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    isDateFilterActive
                        ? (isBn ? '📅 ফিল্টার সক্রিয়' : '📅 Date Filter Active')
                        : (isBn ? '📅 তারিখ / মাস / বছর ফিল্টার' : '📅 Search by Date/Month/Year'),
                    style: TextStyle(
                      color: isDateFilterActive ? const Color(0xFF0284C7) : null,
                      fontWeight: isDateFilterActive ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == null) return;
            if (val == 'date_filter') {
              _showDateFilterDialog(context, isBn, isDark);
            } else {
              setState(() {
                _selectedSort = val;
                // If user switches back to 'newest' or 'oldest', clear specific date filter
                _filterDate = null;
                _filterMonth = null;
                _filterYear = null;
              });
            }
          },
        ),
      ),
    );
  }

  void _showDateFilterDialog(BuildContext context, bool isBn, bool isDark) {
    DateTime? tempDate = _filterDate;
    int? tempMonth = _filterMonth;
    int? tempYear = _filterYear;
    int selectedMode = tempDate != null ? 0 : (tempMonth != null ? 1 : (tempYear != null ? 2 : 0));

    final cardBg = isDark ? const Color(0xFF162B27) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];

    final currentYear = DateTime.now().year;
    final years = List<int>.generate(10, (i) => currentYear - 3 + i);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBn ? 'তারিখ / মাস / বছর ফিল্টার' : 'Filter by Date / Month / Year',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: titleColor),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn
                        ? 'পোস্টগুলো নির্দিষ্ট তারিখ, মাস অথবা বছর অনুসারে ফিল্টার করতে নিচের যেকোনো একটি অপশন বেছে নিন:'
                        : 'Choose how you want to filter property listings and tenant demands:',
                    style: TextStyle(fontSize: 12.5, color: subtitleColor),
                  ),
                  const SizedBox(height: 16),

                  // Filter Mode Selector Tabs
                  Row(
                    children: [
                      _buildFilterModeTab(
                        label: isBn ? 'তারিখ' : 'Date',
                        icon: Icons.event_rounded,
                        isSelected: selectedMode == 0,
                        onTap: () => setDialogState(() => selectedMode = 0),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterModeTab(
                        label: isBn ? 'মাস ও বছর' : 'Month & Year',
                        icon: Icons.date_range_rounded,
                        isSelected: selectedMode == 1,
                        onTap: () => setDialogState(() => selectedMode = 1),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterModeTab(
                        label: isBn ? 'শুধু বছর' : 'Year Only',
                        icon: Icons.calendar_today_rounded,
                        isSelected: selectedMode == 2,
                        onTap: () => setDialogState(() => selectedMode = 2),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Mode 0: Specific Date Picker
                  if (selectedMode == 0) ...[
                    Text(
                      isBn ? '১. নির্দিষ্ট তারিখ নির্বাচন করুন:' : '1. Select Specific Date:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempDate = picked;
                            tempMonth = null;
                            tempYear = null;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tempDate != null ? const Color(0xFF0284C7) : Colors.grey.shade400,
                            width: tempDate != null ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: tempDate != null ? const Color(0xFF0284C7) : subtitleColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tempDate != null
                                    ? _formatPostDate(tempDate!, isBn)
                                    : (isBn ? 'ক্যালেন্ডার থেকে তারিখ বেছে নিন...' : 'Pick a date from calendar...'),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: tempDate != null ? FontWeight.bold : FontWeight.normal,
                                  color: tempDate != null ? titleColor : subtitleColor,
                                ),
                              ),
                            ),
                            if (tempDate != null)
                              InkWell(
                                onTap: () => setDialogState(() => tempDate = null),
                                child: const Icon(Icons.clear_rounded, size: 18, color: Colors.redAccent),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Mode 1: Month & Year Selector
                  if (selectedMode == 1) ...[
                    Text(
                      isBn ? '২. মাস ও বছর নির্বাচন করুন:' : '2. Select Month and Year:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Month Dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: tempMonth ?? DateTime.now().month,
                                items: List.generate(12, (i) {
                                  final monthNum = i + 1;
                                  final name = isBn ? bnMonths[i] : enMonths[i];
                                  return DropdownMenuItem(
                                    value: monthNum,
                                    child: Text(name, style: TextStyle(fontSize: 12.5, color: titleColor)),
                                  );
                                }),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      tempMonth = val;
                                      tempYear ??= DateTime.now().year;
                                      tempDate = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Year Dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: tempYear ?? DateTime.now().year,
                                items: years.map((y) {
                                  return DropdownMenuItem(
                                    value: y,
                                    child: Text(
                                      isBn ? y.toString().toLocalizedDigits('bn') : y.toString(),
                                      style: TextStyle(fontSize: 12.5, color: titleColor),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      tempYear = val;
                                      tempMonth ??= DateTime.now().month;
                                      tempDate = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Mode 2: Year Only Selector
                  if (selectedMode == 2) ...[
                    Text(
                      isBn ? '৩. শুধু বছর নির্বাচন করুন:' : '3. Select Year:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: tempYear ?? DateTime.now().year,
                          items: years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text(
                                isBn ? "${y.toString().toLocalizedDigits('bn')} সাল" : "Year $y",
                                style: TextStyle(fontSize: 13, color: titleColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                tempYear = val;
                                tempMonth = null;
                                tempDate = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _filterDate = null;
                    _filterMonth = null;
                    _filterYear = null;
                    _selectedSort = 'newest';
                  });
                },
                child: Text(
                  isBn ? 'রিসেট / মুছুন' : 'Reset / Clear',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isBn ? 'বাতিল' : 'Cancel', style: TextStyle(color: subtitleColor)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (selectedMode == 0) {
                      _filterDate = tempDate;
                      _filterMonth = null;
                      _filterYear = null;
                    } else if (selectedMode == 1) {
                      _filterDate = null;
                      _filterMonth = tempMonth ?? DateTime.now().month;
                      _filterYear = tempYear ?? DateTime.now().year;
                    } else if (selectedMode == 2) {
                      _filterDate = null;
                      _filterMonth = null;
                      _filterYear = tempYear ?? DateTime.now().year;
                    }
                    _selectedSort = 'date_filter';
                  });
                },
                child: Text(
                  isBn ? 'ফিল্টার প্রয়োগ করুন' : 'Apply Filter',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.themeColor.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.themeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.themeColor : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.themeColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPostDate(DateTime dt, bool isBn) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final formatted = '$day/$month/$year';
    return isBn ? formatted.toLocalizedDigits('bn') : formatted;
  }

  String _getBnMonthName(int month) {
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    if (month >= 1 && month <= 12) return bnMonths[month - 1];
    return '';
  }

  String _getEnMonthName(int month) {
    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return enMonths[month - 1];
    return '';
  }

  String _getActiveFilterText(bool isBn) {
    if (_filterDate != null) {
      final dateStr = _formatPostDate(_filterDate!, isBn);
      return isBn ? 'তারিখ: $dateStr' : 'Date: $dateStr';
    }
    if (_filterMonth != null && _filterYear != null) {
      final m = isBn ? _getBnMonthName(_filterMonth!) : _getEnMonthName(_filterMonth!);
      final y = isBn ? _filterYear!.toString().toLocalizedDigits('bn') : _filterYear.toString();
      return isBn ? 'মাস ও বছর: $m $y' : 'Month & Year: $m $y';
    }
    if (_filterMonth != null) {
      final m = isBn ? _getBnMonthName(_filterMonth!) : _getEnMonthName(_filterMonth!);
      return isBn ? 'মাস: $m' : 'Month: $m';
    }
    if (_filterYear != null) {
      final y = isBn ? _filterYear!.toString().toLocalizedDigits('bn') : _filterYear.toString();
      return isBn ? 'বছর: $y সাল' : 'Year: $y';
    }
    return '';
  }

  bool _matchesDateFilter(DateTime postDate) {
    if (_filterDate != null) {
      if (postDate.year != _filterDate!.year ||
          postDate.month != _filterDate!.month ||
          postDate.day != _filterDate!.day) {
        return false;
      }
    }
    if (_filterMonth != null) {
      if (postDate.month != _filterMonth) {
        return false;
      }
    }
    if (_filterYear != null) {
      if (postDate.year != _filterYear) {
        return false;
      }
    }
    return true;
  }

  bool _matchesDateQuery(DateTime date, String? rentalMonth, String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase();
    final qDigits = q.toEnglishDigits();

    final dayStr = date.day.toString();
    final dayPadded = date.day.toString().padLeft(2, '0');
    final monthStr = date.month.toString();
    final monthPadded = date.month.toString().padLeft(2, '0');
    final yearStr = date.year.toString();

    final fullSlash = '$dayPadded/$monthPadded/$yearStr';
    final fullDash = '$dayPadded-$monthPadded-$yearStr';
    final shortSlash = '$dayStr/$monthStr/$yearStr';
    final monthYear = '$monthPadded/$yearStr';

    if (fullSlash.contains(qDigits) ||
        fullDash.contains(qDigits) ||
        shortSlash.contains(qDigits) ||
        monthYear.contains(qDigits) ||
        yearStr.contains(qDigits)) {
      return true;
    }

    const enMonths = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];

    final postMonthEn = enMonths[date.month - 1];
    final postMonthBn = bnMonths[date.month - 1];

    if (postMonthEn.contains(q) || postMonthBn.contains(q)) {
      return true;
    }

    if (rentalMonth != null && rentalMonth.isNotEmpty) {
      final rmLower = rentalMonth.toLowerCase();
      if (rmLower.contains(q)) return true;
      for (int i = 0; i < enMonths.length; i++) {
        if (rmLower.contains(enMonths[i]) && (bnMonths[i].contains(q) || enMonths[i].contains(q))) {
          return true;
        }
        if (rmLower.contains(bnMonths[i]) && (enMonths[i].contains(q) || bnMonths[i].contains(q))) {
          return true;
        }
      }
    }

    return false;
  }

  void _showRejectDialog(BuildContext context, String id, {required bool isProperty, required bool isBn}) {
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
              if (context.mounted) {
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

  void _showDeleteDialog(BuildContext context, String id, {required bool isProperty, required bool isBn}) {
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'পোস্ট মুছে ফেলা হয়েছে।' : 'Post deleted.'), backgroundColor: Colors.redAccent),
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
