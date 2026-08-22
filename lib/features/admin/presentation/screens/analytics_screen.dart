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
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    isBn ? 'সিস্টেম অ্যানালিটিক্স ও চার্টস' : 'System Analytics & Insights',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.themeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'ইউজার প্রবৃদ্ধি, জনপ্রিয় এলাকা ও প্রপার্টি স্ট্যাটাসের লাইভ ভিজ্যুয়ালাইজেশন'
                        : 'Live visualization of user growth, popular locations, and property metrics',
                    style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
                  ),
                  const SizedBox(height: 28),

                  // Analytics Cards Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.8,
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
                  const SizedBox(height: 32),

                  // Popular Areas & Location Breakdown
                  Container(
                    padding: const EdgeInsets.all(24),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn ? 'কোন জেলায় কতটি বাসাভাড়া বিজ্ঞাপন পোস্ট হয়েছে' : 'Property distribution across districts',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Divider(height: 24),
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
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 18, color: AppColors.themeColor),
                                            const SizedBox(width: 8),
                                            Text(areaName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                          ],
                                        ),
                                        Text('$count ${isBn ? "টি বাসা" : "properties"} (${(percentage * 100).toInt()}%)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        minHeight: 8,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(progressLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
