import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/tenant_demand_firestore_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/edit_demand_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/show_demand_details_screen.dart';

class MyDemandScreen extends StatelessWidget {
  const MyDemandScreen({super.key});

  static const String name = '/my-demand';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (userProvider.isGuest || user == null) {
      return Scaffold(
        appBar: MainAppBar(
          automaticallyImplyLeading: true,
          title: Text(
            l10n.myDemands,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'আপনার পোস্ট করা চাহিদা দেখতে সাইন ইন করুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, SignInScreen.name),
                  child: Text(l10n.signIn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final firestoreService = TenantDemandFirestoreService();

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.myDemands,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: StreamBuilder<List<TenantDemandModel>>(
        stream: firestoreService.streamTenantDemands(user.uid, tenantEmail: user.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final demands = snapshot.data ?? [];

          if (demands.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: demands.length,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _MyDemandCard(demand: demands[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic l10n) {
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
                Icons.post_add_rounded,
                size: 64,
                color: AppColors.themeColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noDemandsYet,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনি এখনো কোনো বাসাভাড়ার চাহিদা পোস্ট করেননি। আপনার চাহিদা পোস্ট করতে নিচের বাটনে চাপ দিন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.postNewDemand),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyDemandCard extends StatelessWidget {
  const _MyDemandCard({required this.demand});

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
          // Header Badges & Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Month Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    demand.month.getLocalizedMonth(l10n),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // House Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.themeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    demand.houseType.getLocalizedLabel(l10n),
                    style: const TextStyle(
                      color: AppColors.themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),

                // Date
                Text(
                  _formatDate(demand.postDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget & Tenant Type Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '৳ ${demand.budgetRange ?? "বাজেট নির্ধারিত নেই"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.themeColor,
                      ),
                    ),
                    if (demand.tenantType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          demand.tenantType!.getLocalizedLabel(l10n),
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.themeColor),
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
                const SizedBox(height: 6),

                // Room / Seat info
                Row(
                  children: [
                    const Icon(Icons.bed_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      demand.roomOrSeat.getLocalizedRoomOrSeat(l10n),
                      style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    if (demand.userWhatsApp.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      const Icon(Icons.chat_outlined, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'হোয়াটসঅ্যাপ যুক্ত',
                        style: TextStyle(fontSize: 11.5, color: Colors.green[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),

                if (demand.detailedDescription.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    demand.detailedDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // 3 Action Buttons (View, Edit, Delete)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // 1. VIEW BUTTON
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

                // 2. EDIT BUTTON
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditDemandScreen(demand: demand),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(l10n.editDemand, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),

                // 3. DELETE BUTTON
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _confirmDelete(context, l10n),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(l10n.deletePhoto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.deleteDemandConfirmTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(l10n.deleteDemandConfirmSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await TenantDemandFirestoreService().deleteDemand(demand.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.demandDeletedSuccess),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('মুছে ফেলুন'),
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

