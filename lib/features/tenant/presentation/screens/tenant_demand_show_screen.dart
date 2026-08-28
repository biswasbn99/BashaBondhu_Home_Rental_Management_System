import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/tenant_demand_firestore_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/post_icon.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/show_demand_details_screen.dart';

class TenantDemandShowScreen extends StatelessWidget {
  const TenantDemandShowScreen({super.key});

  static const String name = '/tenant-demand-show';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final bool isGuest = userProvider.isGuest;
    final bool isOwner = userProvider.user?.userType == 'House Owner';
    final firestoreService = TenantDemandFirestoreService();

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        titleSpacing: (isGuest || isOwner) ? 12 : 20,
        actions: isGuest
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FreePostButton(),
                ),
              ]
            : null,
      ),
      body: StreamBuilder<List<TenantDemandModel>>(
        stream: firestoreService.streamAllDemands(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final demands = snapshot.data ?? [];

          if (demands.isEmpty) {
            return _buildEmptyState(context, l10n, theme);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: demands.length,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _DemandCard(demand: demands[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 64,
                color: AppColors.themeColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'বর্তমানে কোনো ভাড়াটিয়ার চাহিদা নেই',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'নতুন কোনো ভাড়াটিয়া বাসাভাড়ার চাহিদা পোস্ট করলে তা এখানে স্বয়ংক্রিয়ভাবে প্রদর্শিত হবে।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  const _DemandCard({required this.demand});

  final TenantDemandModel demand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;

    final locationText = [
      if (demand.subArea != null) demand.subArea!.getLocalizedName(languageCode),
      demand.area.getLocalizedName(languageCode),
      demand.district.getLocalizedName(languageCode),
    ].where((e) => e.isNotEmpty).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
                  child: Text(
                    demand.userName.isNotEmpty ? demand.userName[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      color: AppColors.themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                              demand.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ভাড়াটিয়া',
                              style: TextStyle(
                                color: AppColors.themeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(demand.postDate),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Budget
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳ ${demand.budgetRange ?? "-"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.themeColor,
                      ),
                    ),
                    Text(
                      demand.month.getLocalizedMonth(l10n),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // House Type & Tenant Type Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${demand.houseType.getLocalizedLabel(l10n)} • ${demand.roomOrSeat.getLocalizedRoomOrSeat(l10n)}',
                        style: const TextStyle(
                          color: AppColors.themeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (demand.tenantType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          demand.tenantType!.getLocalizedLabel(l10n),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                if (demand.detailedDescription.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    demand.detailedDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contact Actions Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900]!.withValues(alpha: 0.5) : Colors.grey[50]!,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Call Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.themeColor,
                      side: const BorderSide(color: AppColors.themeColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('কল করুন: ${demand.userMobile}'),
                          backgroundColor: AppColors.themeColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: Text(l10n.callNow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (demand.userWhatsApp.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  // WhatsApp Button
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('হোয়াটসঅ্যাপ: ${demand.userWhatsApp}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                  ),
                ],
                const SizedBox(width: 8),
                // View Details Button
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ShowDemandDetailsScreen.name,
                        arguments: demand,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(l10n.viewDetails, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘন্টা আগে';
    } else {
      return '${diff.inDays} দিন আগে';
    }
  }
}

