import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

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

            final int totalUsers = users.length;
            final int owners = users.where((u) => u.userType == 'House Owner').length;
            final int tenants = users.where((u) => u.userType == 'Tenant').length;
            final int verified = users.where((u) => u.nidFrontImageUrl.isNotEmpty).length;

            final int totalProps = properties.length;
            final int approved = properties.where((p) => p.isAvailable).length;

            // Area Count Map
            final Map<String, int> areaMap = {};
            for (final p in properties) {
              final areaName = p.district.name.isNotEmpty ? p.district.name : 'Dhaka';
              areaMap[areaName] = (areaMap[areaName] ?? 0) + 1;
            }
            final sortedAreas = areaMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    isBn ? 'সিস্টেম অ্যানালিটিক্স ও চার্টস' : 'System Analytics & Insights',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.themeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'ইউজার প্রবৃদ্ধি, জনপ্রিয় এলাকা ও প্রপার্টি স্ট্যাটাসের লাইভ ভিজ্যুয়ালাইজেশন'
                        : 'Live visualization of user growth, popular locations, and property metrics',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Analytics Cards Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 580 ? 2 : 1);
                      final double aspectRatio = constraints.maxWidth > 900 ? 1.8 : (constraints.maxWidth > 580 ? 1.6 : 2.2);

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: aspectRatio,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildAnalyticalMetricCard(
                            isBn ? 'ইউজার অনুপাত (Owner vs Tenant)' : 'User Ratio (Owner vs Tenant)',
                            '$owners Owners / $tenants Tenants',
                            Icons.pie_chart_rounded,
                            Colors.blueAccent,
                            isDark,
                            progress: totalUsers > 0 ? (owners / totalUsers) : 0.5,
                            progressLabel: '${totalUsers > 0 ? ((owners / totalUsers) * 100).toInt() : 0}% Owners',
                          ),
                          _buildAnalyticalMetricCard(
                            isBn ? 'এনআইডি ভেরিফিকেশন রেট' : 'NID Verification Rate',
                            '$verified / $totalUsers Verified',
                            Icons.verified_user_rounded,
                            Colors.green,
                            isDark,
                            progress: totalUsers > 0 ? (verified / totalUsers) : 0.0,
                            progressLabel: '${totalUsers > 0 ? ((verified / totalUsers) * 100).toInt() : 0}% Verified',
                          ),
                          _buildAnalyticalMetricCard(
                            isBn ? 'বিজ্ঞাপন অনুমোদন রেট' : 'Property Approval Rate',
                            '$approved / $totalProps Active',
                            Icons.home_work_rounded,
                            AppColors.themeColor,
                            isDark,
                            progress: totalProps > 0 ? (approved / totalProps) : 0.0,
                            progressLabel: '${totalProps > 0 ? ((approved / totalProps) * 100).toInt() : 0}% Approved',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Popular Areas & Location Breakdown
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2625) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'সবচেয়ে জনপ্রিয় এলাকা ও জেলাসমূহ (Top Locations)' : 'Most Popular Areas & Districts',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn ? 'কোন জেলায় কতটি বাসাভাড়া বিজ্ঞাপন পোস্ট হয়েছে' : 'Property distribution across districts',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Divider(height: 20),
                        if (sortedAreas.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No location data available')),
                          )
                        else
                          Column(
                            children: sortedAreas.take(6).map((entry) {
                              final areaName = entry.key;
                              final count = entry.value;
                              final double percentage = totalProps > 0 ? (count / totalProps) : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: AppColors.themeColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            areaName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$count ${isBn ? "টি" : "props"} (${(percentage * 100).toInt()}%)',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        minHeight: 7,
                                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.themeColor),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticalMetricCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark, {
    required double progress,
    required String progressLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.bold),
          ),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: Text(progressLabel, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
