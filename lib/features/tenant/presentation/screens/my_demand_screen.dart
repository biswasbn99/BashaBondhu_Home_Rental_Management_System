import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/tenant_demand_firestore_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/language_action_button.dart';
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
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: MainAppBar(
          automaticallyImplyLeading: true,
          actions: const [
            LanguageActionButton(),
          ],
          title: Text(
            l10n.myDemands,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  isBn ? 'আপনার পোস্ট করা চাহিদা দেখতে সাইন ইন করুন' : 'Please sign in to view your posted demands',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
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
        actions: const [
          LanguageActionButton(),
        ],
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
    final isBn = l10n.localeName == 'bn';
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
              isBn
                  ? 'আপনি এখনো কোনো বাসাভাড়ার চাহিদা পোস্ট করেননি। আপনার চাহিদা পোস্ট করতে নিচের বাটনে চাপ দিন।'
                  : 'You have not posted any rental demands yet. Tap the button below to post your requirements.',
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
                const SizedBox(width: 6),

                // Status Badge (Fulfilled vs Looking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: demand.isFulfilled
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: demand.isFulfilled ? Colors.green : Colors.blue,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        demand.isFulfilled ? Icons.check_circle_rounded : Icons.search_rounded,
                        size: 12,
                        color: demand.isFulfilled ? Colors.green[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        demand.isFulfilled
                            ? (languageCode == 'bn' ? 'বাসা পাওয়া গেছে' : 'Fulfilled')
                            : (languageCode == 'bn' ? 'বাসা খুঁজছি' : 'Looking'),
                        style: TextStyle(
                          color: demand.isFulfilled ? Colors.green[800] : Colors.blue[800],
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Date
                Text(
                  _formatDate(demand.postDate, languageCode),
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
                      demand.budgetRange != null
                          ? '৳ ${(demand.budgetRange!).toLocalizedDigits(languageCode)}'
                          : (languageCode == 'bn' ? 'বাজেট নির্ধারিত নেই' : 'Budget not set'),
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

          // --- 1. TOGGLE FULFILLED BUTTON ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: demand.isFulfilled
                      ? Colors.blue.withValues(alpha: isDark ? 0.18 : 0.08)
                      : Colors.green.withValues(alpha: isDark ? 0.18 : 0.08),
                  foregroundColor: demand.isFulfilled
                      ? (isDark ? Colors.lightBlueAccent : Colors.blue[800])
                      : (isDark ? Colors.greenAccent : Colors.green[800]),
                  side: BorderSide(
                    color: demand.isFulfilled ? Colors.blue : Colors.green,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(
                  demand.isFulfilled ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(
                  demand.isFulfilled
                      ? (languageCode == 'bn' ? 'পুনরায় খুঁজছি (Show Demand)' : 'Reopen Demand (Show Post)')
                      : (languageCode == 'bn' ? 'বাসা পাওয়া গেছে (Hide Demand)' : 'Found Home (Hide Demand)'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: () => _confirmToggleFulfilled(context, languageCode),
              ),
            ),
          ),

          // --- 2. Action Buttons (View, Edit, Delete) ---
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

  void _confirmToggleFulfilled(BuildContext context, String languageCode) {
    final isBn = languageCode == 'bn';
    final isCurrentlyFulfilled = demand.isFulfilled;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCurrentlyFulfilled ? Icons.replay_rounded : Icons.check_circle_rounded,
              color: isCurrentlyFulfilled ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isCurrentlyFulfilled
                    ? (isBn ? 'চাহিদাপত্রটি পুনরায় চালু করবেন?' : 'Reopen Demand?')
                    : (isBn ? 'বাসা পাওয়া গেছে নিশ্চিত করবেন?' : 'Mark as Found Home?'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isCurrentlyFulfilled
              ? (isBn
                  ? 'এই চাহিদাপত্রটি পুনরায় সক্রিয় হবে এবং সকল বাড়িওয়ালা তাদের ডিম্যান্ড স্ক্রিনে এটি দেখতে পাবেন।'
                  : 'This demand will be marked as active and visible again to all House Owners.')
              : (isBn
                  ? 'এই চাহিদাপত্রটি "বাসা পাওয়া গেছে" হিসেবে চিহ্নিত হবে এবং সকল বাড়িওয়ালার স্ক্রিন থেকে সম্পূর্ণ লুকিয়ে রাখা হবে।'
                  : 'This demand will be marked as fulfilled and completely hidden from House Owners.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyFulfilled ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await TenantDemandFirestoreService().toggleDemandFulfilledStatus(
                demand.id,
                !isCurrentlyFulfilled,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCurrentlyFulfilled
                          ? (isBn ? 'চাহিদাপত্রটি পুনরায় সক্রিয় করা হয়েছে!' : 'Demand is now active and visible to House Owners!')
                          : (isBn ? 'চাহিদাপত্রটি হাইড করা হয়েছে (বাসা পাওয়া গেছে)।' : 'Demand marked as Fulfilled and hidden from House Owners.'),
                    ),
                    backgroundColor: isCurrentlyFulfilled ? Colors.blue : Colors.green,
                  ),
                );
              }
            },
            child: Text(
              isCurrentlyFulfilled
                  ? (isBn ? 'হ্যাঁ, চালু করুন' : 'Yes, Reopen')
                  : (isBn ? 'হ্যাঁ, বাসা পেয়েছি' : 'Yes, Found Home'),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, String languageCode) {
    final diff = DateTime.now().difference(date);
    final isBn = languageCode == 'bn';
    if (diff.inMinutes < 60) {
      return isBn
          ? '${diff.inMinutes.toString().toLocalizedDigits("bn")} মিনিট আগে'
          : '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return isBn
          ? '${diff.inHours.toString().toLocalizedDigits("bn")} ঘন্টা আগে'
          : '${diff.inHours} hours ago';
    } else {
      return isBn
          ? '${diff.inDays.toString().toLocalizedDigits("bn")} দিন আগে'
          : '${diff.inDays} days ago';
    }
  }
}

