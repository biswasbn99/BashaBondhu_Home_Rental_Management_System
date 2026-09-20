import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../subscription/data/services/subscription_firestore_service.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../data/services/admin_firestore_service.dart';
import '../../data/services/admin_report_pdf_service.dart';
import '../widgets/admin_pdf_preview_modal.dart';

enum ReportTab { revenue, properties, demands, houseOwners, tenants }
enum DatePreset { allTime, today, thisWeek, thisMonth, thisYear, custom }

class ReportsManagementView extends StatefulWidget {
  const ReportsManagementView({super.key});

  @override
  State<ReportsManagementView> createState() => _ReportsManagementViewState();
}

class _ReportsManagementViewState extends State<ReportsManagementView> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final SubscriptionFirestoreService _subscriptionService = SubscriptionFirestoreService();
  final AdminReportPdfService _pdfService = AdminReportPdfService();

  ReportTab _activeTab = ReportTab.revenue;
  DatePreset _datePreset = DatePreset.allTime;
  DateTimeRange? _customDateRange;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime? get _startDate {
    final now = DateTime.now();
    switch (_datePreset) {
      case DatePreset.allTime:
        return null;
      case DatePreset.today:
        return DateTime(now.year, now.month, now.day);
      case DatePreset.thisWeek:
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      case DatePreset.thisMonth:
        return DateTime(now.year, now.month, 1);
      case DatePreset.thisYear:
        return DateTime(now.year, 1, 1);
      case DatePreset.custom:
        return _customDateRange?.start;
    }
  }

  DateTime? get _endDate {
    final now = DateTime.now();
    switch (_datePreset) {
      case DatePreset.allTime:
        return null;
      case DatePreset.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DatePreset.thisWeek:
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        return startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case DatePreset.thisMonth:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case DatePreset.thisYear:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case DatePreset.custom:
        return _customDateRange != null
            ? DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59)
            : null;
    }
  }

  bool _isWithinDateRange(DateTime? date) {
    if (date == null) return _datePreset == DatePreset.allTime;
    final start = _startDate;
    final end = _endDate;
    if (start != null && date.isBefore(start)) return false;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }

  Future<void> _selectCustomDateRange(bool isBn) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
      helpText: isBn ? 'কাস্টম তারিখের সীমা নির্বাচন করুন' : 'Select Custom Date Range',
      cancelText: isBn ? 'বাতিল' : 'Cancel',
      confirmText: isBn ? 'প্রয়োগ করুন' : 'Apply',
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _datePreset = DatePreset.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isBn = l10n.localeName == 'bn';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0B1917) : const Color(0xFFF8FAFC);
    final Color cardBg = isDark ? const Color(0xFF112320) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1F3D37) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 700;
          final double horizontalPadding = isCompact ? 14.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                _buildHeader(isBn, isDark, isCompact),
                const SizedBox(height: 16),

                // Responsive Tab Selector
                _buildTabSelector(isBn, isDark, borderColor),
                const SizedBox(height: 16),

                // Search and Filter Bar
                _buildFilterBar(isBn, isDark, cardBg, borderColor, isCompact),
                const SizedBox(height: 20),

                // Tab Content Body
                switch (_activeTab) {
                  ReportTab.revenue => _buildRevenueTab(isBn, isDark, cardBg, borderColor, isCompact),
                  ReportTab.properties => _buildPropertiesTab(isBn, isDark, cardBg, borderColor, isCompact),
                  ReportTab.demands => _buildDemandsTab(isBn, isDark, cardBg, borderColor, isCompact),
                  ReportTab.houseOwners => _buildHouseOwnersTab(isBn, isDark, cardBg, borderColor, isCompact),
                  ReportTab.tenants => _buildTenantsTab(isBn, isDark, cardBg, borderColor, isCompact),
                },
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================
  Widget _buildHeader(bool isBn, bool isDark, bool isCompact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppColors.themeColor, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  isBn ? 'রিপোর্ট ও অ্যানালিটিক্স হাব' : 'Report & Analytics Hub',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 18 : 22,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isBn
                  ? 'রেভিনিউ, বাড়িভাড়া বিজ্ঞাপন, ভাড়াটিয়ার চাহিদা ও পৃথক ইউজার অডিট রিপোর্ট তৈরি ও প্রিন্ট করুন'
                  : 'Generate, audit, and print official reports for revenue, listings, demands, owners & tenants',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB SELECTOR (RESPONSIVE HORIZONTAL SCROLL)
  // ==========================================================================
  Widget _buildTabSelector(bool isBn, bool isDark, Color borderColor) {
    final List<Map<String, dynamic>> tabs = [
      {
        'tab': ReportTab.revenue,
        'label': isBn ? 'আয় / রেভিনিউ' : 'Revenue & Subscriptions',
        'icon': Icons.monetization_on_rounded,
        'color': const Color(0xFF00897B),
      },
      {
        'tab': ReportTab.properties,
        'label': isBn ? 'বাড়িভাড়া বিজ্ঞাপন' : 'Property Listings',
        'icon': Icons.apartment_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'tab': ReportTab.demands,
        'label': isBn ? 'ভাড়াটিয়াদের চাহিদা' : 'Tenant Demands',
        'icon': Icons.person_pin_circle_rounded,
        'color': const Color(0xFF4F46E5),
      },
      {
        'tab': ReportTab.houseOwners,
        'label': isBn ? 'বাড়িওয়ালা ও NID অডিট' : 'House Owners & KYC',
        'icon': Icons.real_estate_agent_rounded,
        'color': const Color(0xFF0D9488),
      },
      {
        'tab': ReportTab.tenants,
        'label': isBn ? 'ভাড়াটিয়া ও NID অডিট' : 'Tenants & KYC',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF7C3AED),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final ReportTab tab = t['tab'] as ReportTab;
          final String label = t['label'] as String;
          final IconData icon = t['icon'] as IconData;
          final Color color = t['color'] as Color;
          final bool isSelected = _activeTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _activeTab = tab),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.12))
                        : (isDark ? const Color(0xFF162824) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : borderColor,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: isSelected ? color : (isDark ? Colors.grey[400] : Colors.grey[600]), size: 17),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected
                              ? (isDark ? Colors.white : color)
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================================
  // DATE FILTER & SEARCH BAR (RESPONSIVE)
  // ==========================================================================
  Widget _buildFilterBar(bool isBn, bool isDark, Color cardBg, Color borderColor, bool isCompact) {
    final dateFormat = DateFormat('dd MMM yyyy');
    String rangeLabel = isBn ? 'সর্বমোট (All Time)' : 'All Time';
    if (_startDate != null && _endDate != null) {
      rangeLabel = '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
    } else if (_startDate != null) {
      rangeLabel = isBn ? '${dateFormat.format(_startDate!)} হতে' : 'From ${dateFormat.format(_startDate!)}';
    }

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Custom Date Row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Search Field
              SizedBox(
                width: isCompact ? double.infinity : 320,
                height: 42,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isBn ? 'নাম, ইমেইল, এলাকা বা TrxID খুঁজুন...' : 'Search by name, email, area, TrxID...',
                    hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 17),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF162824) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),

              // Date Range Indicator & Picker
              InkWell(
                onTap: () => _selectCustomDateRange(isBn),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _datePreset == DatePreset.custom
                        ? AppColors.themeColor.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF162824) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _datePreset == DatePreset.custom ? AppColors.themeColor : borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.themeColor),
                      const SizedBox(width: 6),
                      Text(
                        rangeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(DatePreset.allTime, isBn ? 'সর্বমোট' : 'All Time', isDark),
                _buildPresetChip(DatePreset.today, isBn ? 'আজকে' : 'Today', isDark),
                _buildPresetChip(DatePreset.thisWeek, isBn ? 'চলতি সপ্তাহ' : 'This Week', isDark),
                _buildPresetChip(DatePreset.thisMonth, isBn ? 'চলতি মাস' : 'This Month', isDark),
                _buildPresetChip(DatePreset.thisYear, isBn ? 'চলতি বছর' : 'This Year', isDark),
                if (_datePreset != DatePreset.allTime || _searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _datePreset = DatePreset.allTime;
                        _customDateRange = null;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 15, color: Colors.redAccent),
                    label: Text(
                      isBn ? 'রিসেট' : 'Reset',
                      style: const TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(DatePreset preset, String label, bool isDark) {
    final bool isSelected = _datePreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        selected: isSelected,
        selectedColor: AppColors.themeColor,
        backgroundColor: isDark ? const Color(0xFF162824) : const Color(0xFFF1F5F9),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _datePreset = preset;
              _customDateRange = null;
            });
          }
        },
      ),
    );
  }

  // ==========================================================================
  // 1. REVENUE & FINANCIAL REPORT TAB
  // ==========================================================================
  Widget _buildRevenueTab(bool isBn, bool isDark, Color cardBg, Color borderColor, bool isCompact) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return StreamBuilder<List<SubscriptionTransactionModel>>(
      stream: _subscriptionService.streamAllTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.themeColor)),
          );
        }

        final allTransactions = snapshot.data ?? [];

        final filtered = allTransactions.where((t) {
          if (!_isWithinDateRange(t.purchasedAt)) return false;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchEmail = t.userEmail.toLowerCase().contains(query);
            final matchMobile = t.userMobile.contains(query) || t.senderPhone.contains(query);
            final matchTrx = t.transactionId.toLowerCase().contains(query);
            final matchPlan = t.planTitle.toLowerCase().contains(query);
            if (!matchEmail && !matchMobile && !matchTrx && !matchPlan) return false;
          }
          return true;
        }).toList();

        final double totalRevenue = filtered.fold(0.0, (sum, t) => sum + t.amountPaid);
        final int totalCount = filtered.length;
        final double avgOrder = totalCount > 0 ? (totalRevenue / totalCount) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Row & PDF Button (Responsive Wrap)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildKpiCard(
                      title: isBn ? 'মোট অর্জিত আয়' : 'Total Gross Revenue',
                      value: '৳ ${currencyFormat.format(totalRevenue)}',
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFF00897B),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'মোট ট্রানজাকশন' : 'Transactions Count',
                      value: totalCount.toString(),
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF0284C7),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'গড় পেমেন্ট' : 'Avg. Transaction',
                      value: '৳ ${currencyFormat.format(avgOrder)}',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF4F46E5),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          AdminPdfPreviewModal.show(
                            context,
                            pdfFuture: () => _pdfService.generateRevenueReportPdf(
                              transactions: filtered,
                              startDate: _startDate,
                              endDate: _endDate,
                              isBn: isBn,
                            ),
                            title: isBn ? 'আয় ও সাবস্ক্রিপশন স্টেটমেন্ট (PDF)' : 'Revenue & Subscriptions Statement (PDF)',
                            fileName: 'BashaBondhu_Revenue_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                            isBn: isBn,
                          );
                        },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(isBn ? 'রেভিনিউ PDF প্রিন্ট' : 'Print Revenue Statement'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Revenue Transactions Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      isBn ? 'কোনো সাবস্ক্রিপশন লেনদেনের রেকর্ড পাওয়া যায়নি' : 'No subscription transaction records found',
                      isBn,
                      isDark,
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1A332E) : const Color(0xFFF1F5F9)),
                        horizontalMargin: 16,
                        columnSpacing: 20,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(label: Text(isBn ? 'Trx ID ও প্যাকেজ' : 'Trx ID & Plan', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'ইউজার বিবরণ' : 'User Details', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'মেথড' : 'Method', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'টাকা' : 'Amount', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'তারিখ' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'রিসিট' : 'Receipt', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((t) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.transactionId.isNotEmpty ? t.transactionId : (t.id.length > 8 ? t.id.substring(0, 8) : t.id),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.themeColor),
                                    ),
                                    Text(
                                      t.planTitle,
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.userEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(t.userMobile.isNotEmpty ? t.userMobile : (t.senderPhone.isNotEmpty ? t.senderPhone : 'N/A'),
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.teal[900] : Colors.teal[50])?.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.paymentMethod.toUpperCase(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00897B)),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '৳ ${currencyFormat.format(t.amountPaid)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00897B), fontSize: 13.5),
                                ),
                              ),
                              DataCell(
                                Text(
                                  dateFormat.format(t.purchasedAt),
                                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.receipt_rounded, color: AppColors.themeColor, size: 20),
                                  tooltip: isBn ? 'রিসিট PDF প্রিন্ট' : 'Print Receipt PDF',
                                  onPressed: () {
                                    AdminPdfPreviewModal.show(
                                      context,
                                      pdfFuture: () => _pdfService.generateSingleTransactionReceiptPdf(
                                        transaction: t,
                                        isBn: isBn,
                                      ),
                                      title: isBn ? 'অফিসিয়াল পেমেন্ট রিসিট স্লিপ' : 'Official Payment Receipt Slip',
                                      fileName: 'Receipt_${t.transactionId.isNotEmpty ? t.transactionId : t.id}.pdf',
                                      isBn: isBn,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // 2. PROPERTY LISTINGS REPORT TAB
  // ==========================================================================
  Widget _buildPropertiesTab(bool isBn, bool isDark, Color cardBg, Color borderColor, bool isCompact) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('dd MMM yyyy');

    return StreamBuilder<List<PropertyModel>>(
      stream: _adminService.streamAllProperties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.themeColor)),
          );
        }

        final allProperties = snapshot.data ?? [];

        final filtered = allProperties.where((p) {
          if (!_isWithinDateRange(p.postDate)) return false;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchAddress = p.shortAddress.toLowerCase().contains(query) ||
                p.area.name.toLowerCase().contains(query) ||
                p.area.bnName.toLowerCase().contains(query);
            final matchOwner = p.contactName.toLowerCase().contains(query) ||
                p.ownerEmail.toLowerCase().contains(query);
            final matchType = p.houseType.name.toLowerCase().contains(query);
            if (!matchAddress && !matchOwner && !matchType) return false;
          }
          return true;
        }).toList();

        final int total = filtered.length;
        final int approved = filtered.where((p) => p.isApproved && p.approvalStatus != 'rejected').length;
        final int pending = filtered.where((p) => p.approvalStatus == 'pending').length;
        final double totalRent = filtered.fold(0.0, (sum, p) {
          final rent = double.tryParse(p.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          return sum + rent;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildKpiCard(
                      title: isBn ? 'মোট বিজ্ঞাপন' : 'Total Listings',
                      value: total.toString(),
                      icon: Icons.apartment_rounded,
                      color: const Color(0xFF0284C7),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'অনুমোদিত ও লাইভ' : 'Approved & Live',
                      value: approved.toString(),
                      icon: Icons.verified_rounded,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'রিভিউ পেন্ডিং' : 'Pending Review',
                      value: pending.toString(),
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'সম্ভাব্য মোট ভাড়া' : 'Total Est. Rent',
                      value: '৳ ${currencyFormat.format(totalRent)}',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF00897B),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          AdminPdfPreviewModal.show(
                            context,
                            pdfFuture: () => _pdfService.generatePropertiesReportPdf(
                              properties: filtered,
                              startDate: _startDate,
                              endDate: _endDate,
                              isBn: isBn,
                            ),
                            title: isBn ? 'বাড়িভাড়া বিজ্ঞাপন ও ইনভেন্টরি রিপোর্ট (PDF)' : 'Property Listings Inventory Report (PDF)',
                            fileName: 'BashaBondhu_Properties_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                            isBn: isBn,
                          );
                        },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(isBn ? 'বিজ্ঞাপন PDF প্রিন্ট' : 'Print Properties PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Properties Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      isBn ? 'কোনো বাড়িভাড়া বিজ্ঞাপনের রেকর্ড পাওয়া যায়নি' : 'No property listings found',
                      isBn,
                      isDark,
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1A332E) : const Color(0xFFF1F5F9)),
                        horizontalMargin: 16,
                        columnSpacing: 20,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(label: Text(isBn ? 'বিজ্ঞাপন / ধরন' : 'Listing / Type', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'লোকেশন ও ঠিকানা' : 'Location & Address', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'ভাড়া মূল্য' : 'Rent Amount', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'বাড়িওয়ালা' : 'Owner', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'স্ট্যাটাস' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'তারিখ' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((p) {
                          final isApproved = p.isApproved && p.approvalStatus != 'rejected';
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.houseType.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    Text(
                                      isBn ? 'বাড়িভাড়া' : 'Rental Property',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  p.shortAddress.isNotEmpty ? p.shortAddress : '${p.area.name}, ${p.district.name}',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '৳ ${p.amount}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00897B), fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.contactName.isNotEmpty ? p.contactName : p.ownerEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(p.userMobile.isNotEmpty ? p.userMobile : 'N/A', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isApproved ? Colors.green : Colors.amber).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.approvalStatus.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isApproved ? Colors.green : Colors.amber[800]),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(dateFormat.format(p.postDate), style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // 3. TENANT DEMANDS REPORT TAB
  // ==========================================================================
  Widget _buildDemandsTab(bool isBn, bool isDark, Color cardBg, Color borderColor, bool isCompact) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return StreamBuilder<List<TenantDemandModel>>(
      stream: _adminService.streamAllDemands(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.themeColor)),
          );
        }

        final allDemands = snapshot.data ?? [];

        final filtered = allDemands.where((d) {
          if (!_isWithinDateRange(d.postDate)) return false;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchName = d.userName.toLowerCase().contains(query) || d.tenantEmail.toLowerCase().contains(query);
            final matchArea = d.area.name.toLowerCase().contains(query) || d.area.bnName.toLowerCase().contains(query) || d.district.name.toLowerCase().contains(query);
            final matchType = d.houseType.name.toLowerCase().contains(query);
            if (!matchName && !matchArea && !matchType) return false;
          }
          return true;
        }).toList();

        final int total = filtered.length;
        final int approved = filtered.where((d) => d.isApproved && d.approvalStatus != 'rejected').length;
        final int pending = filtered.where((d) => d.approvalStatus == 'pending').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildKpiCard(
                      title: isBn ? 'মোট চাহিদা পোস্ট' : 'Total Demands',
                      value: total.toString(),
                      icon: Icons.person_pin_circle_rounded,
                      color: const Color(0xFF4F46E5),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'অনুমোদিত ও লাইভ' : 'Approved & Live',
                      value: approved.toString(),
                      icon: Icons.verified_rounded,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'রিভিউ পেন্ডিং' : 'Pending Review',
                      value: pending.toString(),
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          AdminPdfPreviewModal.show(
                            context,
                            pdfFuture: () => _pdfService.generateDemandsReportPdf(
                              demands: filtered,
                              startDate: _startDate,
                              endDate: _endDate,
                              isBn: isBn,
                            ),
                            title: isBn ? 'ভাড়াটিয়াদের চাহিদা অডিট রিপোর্ট (PDF)' : 'Tenant Rental Demands Report (PDF)',
                            fileName: 'BashaBondhu_Tenant_Demands_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                            isBn: isBn,
                          );
                        },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(isBn ? 'চাহিদা PDF প্রিন্ট' : 'Print Demands PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Demands Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      isBn ? 'কোনো ভাড়াটিয়ার চাহিদার রেকর্ড পাওয়া যায়নি' : 'No tenant demand records found',
                      isBn,
                      isDark,
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1A332E) : const Color(0xFFF1F5F9)),
                        horizontalMargin: 16,
                        columnSpacing: 20,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(label: Text(isBn ? 'ক্যাটাগরি' : 'Category', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'প্রয়োজনীয় এলাকা' : 'Target Location', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'বাজেট সীমা' : 'Budget Range', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'ভাড়াটিয়া' : 'Tenant', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'স্ট্যাটাস' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'তারিখ' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((d) {
                          final isApproved = d.isApproved && d.approvalStatus != 'rejected';
                          final date = dateFormat.format(d.postDate);
                          final loc = '${d.area.name}, ${d.district.name}';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(d.houseType.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              DataCell(
                                Text(loc, style: const TextStyle(fontSize: 12.5)),
                              ),
                              DataCell(
                                Text('৳ ${d.budgetRange ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4F46E5), fontSize: 13)),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.userName.isNotEmpty ? d.userName : d.tenantEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(d.userMobile.isNotEmpty ? d.userMobile : 'N/A', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isApproved ? Colors.green : Colors.amber).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    d.approvalStatus.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isApproved ? Colors.green : Colors.amber[800]),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(date, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // 4. HOUSE OWNERS & KYC AUDIT REPORT TAB
  // ==========================================================================
  Widget _buildHouseOwnersTab(bool isBn, bool isDark, Color cardBg, Color borderColor, bool isCompact) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return StreamBuilder<List<UserModel>>(
      stream: _adminService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.themeColor)),
          );
        }

        final allUsers = snapshot.data ?? [];
        final houseOwners = allUsers.where((u) => u.userType == 'House Owner').toList();

        final filtered = houseOwners.where((u) {
          DateTime? createdDt;
          try {
            createdDt = DateTime.tryParse(u.createdAt);
          } catch (_) {}
          if (!_isWithinDateRange(createdDt)) return false;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final name = u.fullName.toLowerCase();
            final email = u.email.toLowerCase();
            final mobile = u.mobile;
            final city = u.city.toLowerCase();
            if (!name.contains(query) && !email.contains(query) && !mobile.contains(query) && !city.contains(query)) {
              return false;
            }
          }
          return true;
        }).toList();

        final int total = filtered.length;
        final int verified = filtered.where((u) => u.isVerified).length;
        final int pending = filtered.where((u) => u.isVerificationPending).length;
        final int blocked = filtered.where((u) => u.isBlocked).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildKpiCard(
                      title: isBn ? 'মোট বাড়িওয়ালা' : 'Total House Owners',
                      value: total.toString(),
                      icon: Icons.real_estate_agent_rounded,
                      color: const Color(0xFF0D9488),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'NID ভেরিফাইড' : 'NID Verified',
                      value: verified.toString(),
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'ভেরিফিকেশন পেন্ডিং' : 'KYC Pending',
                      value: pending.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'স্থগিত / ব্লকড' : 'Suspended',
                      value: blocked.toString(),
                      icon: Icons.block_rounded,
                      color: const Color(0xFFE53935),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          AdminPdfPreviewModal.show(
                            context,
                            pdfFuture: () => _pdfService.generateHouseOwnersReportPdf(
                              owners: filtered,
                              startDate: _startDate,
                              endDate: _endDate,
                              isBn: isBn,
                            ),
                            title: isBn ? 'বাড়িওয়ালা ও NID অডিট রিপোর্ট (PDF)' : 'House Owners & KYC Audit Report (PDF)',
                            fileName: 'BashaBondhu_House_Owners_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                            isBn: isBn,
                          );
                        },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(isBn ? 'বাড়িওয়ালা PDF প্রিন্ট' : 'Print Owners PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // House Owners Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      isBn ? 'কোনো বাড়িওয়ালার রেকর্ড পাওয়া যায়নি' : 'No house owner records found',
                      isBn,
                      isDark,
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1A332E) : const Color(0xFFF1F5F9)),
                        horizontalMargin: 16,
                        columnSpacing: 20,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(label: Text(isBn ? 'বাড়িওয়ালার নাম' : 'Owner Name', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'ইমেইল ও মোবাইল' : 'Email & Mobile', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'শহর / জেলা' : 'City / District', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'NID স্ট্যাটাস' : 'NID Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'অ্যাকাউন্ট' : 'Account', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'যোগদান' : 'Joined', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((u) {
                          final name = u.fullName.isNotEmpty ? u.fullName : '${u.firstName} ${u.lastName}'.trim();
                          DateTime? createdDt;
                          try {
                            createdDt = DateTime.tryParse(u.createdAt);
                          } catch (_) {}
                          final date = createdDt != null ? dateFormat.format(createdDt) : 'N/A';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(name.isNotEmpty ? name : 'Owner', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(u.mobile.isNotEmpty ? u.mobile : 'N/A', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(u.city.isNotEmpty ? u.city : 'N/A', style: const TextStyle(fontSize: 12.5)),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (u.isVerified ? Colors.green : (u.isVerificationPending ? Colors.amber : Colors.grey)).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.isVerified ? 'VERIFIED' : (u.isVerificationPending ? 'PENDING' : 'UNVERIFIED'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: u.isVerified ? Colors.green : (u.isVerificationPending ? Colors.amber[800] : Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (u.isBlocked ? Colors.red : Colors.green).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.isBlocked ? 'SUSPENDED' : 'ACTIVE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: u.isBlocked ? Colors.red : Colors.green),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(date, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // 5. TENANTS & KYC AUDIT REPORT TAB
  // ==========================================================================
  Widget _buildTenantsTab(bool isBn, bool isDark, Color cardBg, Color borderColor, bool isCompact) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return StreamBuilder<List<UserModel>>(
      stream: _adminService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.themeColor)),
          );
        }

        final allUsers = snapshot.data ?? [];
        final tenants = allUsers.where((u) => u.userType == 'Tenant').toList();

        final filtered = tenants.where((u) {
          DateTime? createdDt;
          try {
            createdDt = DateTime.tryParse(u.createdAt);
          } catch (_) {}
          if (!_isWithinDateRange(createdDt)) return false;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final name = u.fullName.toLowerCase();
            final email = u.email.toLowerCase();
            final mobile = u.mobile;
            final city = u.city.toLowerCase();
            if (!name.contains(query) && !email.contains(query) && !mobile.contains(query) && !city.contains(query)) {
              return false;
            }
          }
          return true;
        }).toList();

        final int total = filtered.length;
        final int verified = filtered.where((u) => u.isVerified).length;
        final int pending = filtered.where((u) => u.isVerificationPending).length;
        final int subscribed = filtered.where((u) => u.isSubscribed).length;
        final int blocked = filtered.where((u) => u.isBlocked).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildKpiCard(
                      title: isBn ? 'মোট ভাড়াটিয়া' : 'Total Tenants',
                      value: total.toString(),
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF7C3AED),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'NID ভেরিফাইড' : 'NID Verified',
                      value: verified.toString(),
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'পেন্ডিং ভেরিফিকেশন' : 'KYC Pending',
                      value: pending.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'প্রিমিয়াম সক্রিয়' : 'Premium Active',
                      value: subscribed.toString(),
                      icon: Icons.workspace_premium_rounded,
                      color: const Color(0xFF0284C7),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildKpiCard(
                      title: isBn ? 'স্থগিত / ব্লকড' : 'Suspended',
                      value: blocked.toString(),
                      icon: Icons.block_rounded,
                      color: const Color(0xFFE53935),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          AdminPdfPreviewModal.show(
                            context,
                            pdfFuture: () => _pdfService.generateTenantsReportPdf(
                              tenants: filtered,
                              startDate: _startDate,
                              endDate: _endDate,
                              isBn: isBn,
                            ),
                            title: isBn ? 'ভাড়াটিয়া ও NID অডিট রিপোর্ট (PDF)' : 'Tenants & KYC Audit Report (PDF)',
                            fileName: 'BashaBondhu_Tenants_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                            isBn: isBn,
                          );
                        },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(isBn ? 'ভাড়াটিয়া PDF প্রিন্ট' : 'Print Tenants PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Tenants Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      isBn ? 'কোনো ভাড়াটিয়ার রেকর্ড পাওয়া যায়নি' : 'No tenant records found',
                      isBn,
                      isDark,
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1A332E) : const Color(0xFFF1F5F9)),
                        horizontalMargin: 16,
                        columnSpacing: 20,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(label: Text(isBn ? 'ভাড়াটিয়ার নাম' : 'Tenant Name', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'ইমেইল ও মোবাইল' : 'Email & Mobile', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'শহর / জেলা' : 'City / District', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'NID স্ট্যাটাস' : 'NID Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'সাবস্ক্রিপশন' : 'Subscription', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'অ্যাকাউন্ট' : 'Account', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isBn ? 'যোগদান' : 'Joined', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((u) {
                          final name = u.fullName.isNotEmpty ? u.fullName : '${u.firstName} ${u.lastName}'.trim();
                          DateTime? createdDt;
                          try {
                            createdDt = DateTime.tryParse(u.createdAt);
                          } catch (_) {}
                          final date = createdDt != null ? dateFormat.format(createdDt) : 'N/A';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(name.isNotEmpty ? name : 'Tenant', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(u.mobile.isNotEmpty ? u.mobile : 'N/A', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(u.city.isNotEmpty ? u.city : 'N/A', style: const TextStyle(fontSize: 12.5)),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (u.isVerified ? Colors.green : (u.isVerificationPending ? Colors.amber : Colors.grey)).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.isVerified ? 'VERIFIED' : (u.isVerificationPending ? 'PENDING' : 'UNVERIFIED'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: u.isVerified ? Colors.green : (u.isVerificationPending ? Colors.amber[800] : Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (u.isSubscribed ? const Color(0xFF7C3AED) : Colors.grey).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.isSubscribed ? 'PREMIUM' : 'FREE TIER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: u.isSubscribed ? const Color(0xFF7C3AED) : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (u.isBlocked ? Colors.red : Colors.green).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.isBlocked ? 'SUSPENDED' : 'ACTIVE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: u.isBlocked ? Colors.red : Colors.green),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(date, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // SHARED UI HELPERS
  // ==========================================================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isBn, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 44, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
