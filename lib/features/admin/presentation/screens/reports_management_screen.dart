import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class ReportsManagementView extends StatefulWidget {
  const ReportsManagementView({super.key});

  @override
  State<ReportsManagementView> createState() => _ReportsManagementViewState();
}

class _ReportsManagementViewState extends State<ReportsManagementView> {
  String _selectedFilter = 'All';
  final AdminFirestoreService _adminService = AdminFirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.streamReports(),
      builder: (context, snapshot) {
        final allReports = snapshot.data ?? [];

        final filteredReports = allReports.where((r) {
          final status = r['status']?.toString() ?? 'pending';
          if (_selectedFilter == 'Pending') return status == 'pending';
          if (_selectedFilter == 'Resolved') return status == 'resolved';
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Wrap
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
                        isBn ? 'রিপোর্ট ও অভিযোগ ম্যানেজমেন্ট' : 'Reports Management',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.themeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn
                            ? 'ভুয়া বিজ্ঞাপন, স্প্যাম ও অভিযোগ পরিচালনা করুন (${filteredReports.length} টি রিপোর্ট)'
                            : 'Review and resolve fake listings and spam reports (${filteredReports.length} reports)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  _buildFilterDropdown(isBn, isDark),
                ],
              ),
              const SizedBox(height: 20),

              // Reports Table / List
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2625) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: filteredReports.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 44, color: Colors.green),
                              const SizedBox(height: 10),
                              Text(
                                isBn ? 'কোনো নতুন রিপোর্ট বা অভিযোগ নেই' : 'No reports found',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredReports.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final report = filteredReports[idx];
                          final id = report['id'];
                          final title = report['title']?.toString() ?? 'Report #${idx + 1}';
                          final reason = report['reason']?.toString() ?? 'Spam / Fake Listing';
                          final targetId = report['targetPropertyId']?.toString() ?? report['targetUserId']?.toString() ?? 'N/A';
                          final reporter = report['reporterEmail']?.toString() ?? 'Anonymous';
                          final status = report['status']?.toString() ?? 'pending';
                          final isResolved = status == 'resolved';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: (isResolved ? Colors.green : Colors.redAccent).withValues(alpha: 0.12),
                                  child: Icon(
                                    isResolved ? Icons.check_circle_rounded : Icons.report_problem_rounded,
                                    color: isResolved ? Colors.green : Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isResolved ? Colors.green : Colors.redAccent).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isResolved ? (isBn ? 'নিষ্পন্ন' : 'Resolved') : (isBn ? 'পেন্ডিং' : 'Pending'),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isResolved ? Colors.green : Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${isBn ? 'কারণ:' : 'Reason:'} $reason",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${isBn ? 'টার্গেট:' : 'Target:'} $targetId • ${isBn ? 'রিপোর্টার:' : 'By:'} $reporter",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isResolved)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () async {
                                          await _adminService.updateReportStatus(id, 'resolved');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(isBn ? 'রিপোর্ট সমাধান করা হয়েছে!' : 'Report resolved!'), backgroundColor: Colors.green),
                                            );
                                          }
                                        },
                                        child: Text(isBn ? 'সমাধান' : 'Resolve', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      tooltip: isBn ? 'রিপোর্ট মুছুন' : 'Delete Report',
                                      onPressed: () async {
                                        await _adminService.deleteReport(id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(isBn ? 'রিপোর্ট মুছে ফেলা হয়েছে।' : 'Report deleted.'), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
          items: [
            DropdownMenuItem(value: 'All', child: Text(isBn ? 'সকল রিপোর্ট (All)' : 'All Reports')),
            DropdownMenuItem(value: 'Pending', child: Text(isBn ? 'পেন্ডিং (Pending)' : 'Pending Reports')),
            DropdownMenuItem(value: 'Resolved', child: Text(isBn ? 'সমাধানকৃত (Resolved)' : 'Resolved Reports')),
          ],
          onChanged: (val) => setState(() => _selectedFilter = val!),
        ),
      ),
    );
  }
}
